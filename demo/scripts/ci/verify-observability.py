#!/usr/bin/env python3
import json
import pathlib
import re
import sys
from datetime import datetime
from collections.abc import Iterator


REQUEST_ID = "cargo-tracker-ci-observability"
REQUESTS = {
    "success": {
        "trace_id": "11111111111111111111111111111111",
        "path": "/cargo-tracker/rest/cargo",
        "status": 200,
    },
    "invalid": {
        "trace_id": "22222222222222222222222222222222",
        "path": "/cargo-tracker/rest/does-not-exist",
        "status": 404,
    },
}
FORBIDDEN_ATTRIBUTES = {
    "url.query",
    "url.full",
    "http.url",
    "http.target",
    "db.statement",
    "db.connection_string",
    "db.user",
    "http.request.body",
    "http.response.body",
    "http.request.header.authorization",
    "http.request.header.cookie",
    "http.response.header.set_cookie",
}


def fail(message: str) -> None:
    raise ValueError(message)


def records(path: pathlib.Path, label: str) -> list[dict]:
    if not path.is_file() or path.stat().st_size == 0:
        fail(f"missing telemetry: {label} file is absent or empty")
    result = []
    for line_number, line in enumerate(path.read_text().splitlines(), 1):
        try:
            result.append(json.loads(line))
        except json.JSONDecodeError as error:
            fail(f"missing telemetry: {label} is not JSON at line {line_number}: {error}")
    if not result:
        fail(f"missing telemetry: {label} contains no records")
    return result


def value(attribute: dict):
    data = attribute.get("value", attribute)
    for key in (
        "stringValue",
        "intValue",
        "doubleValue",
        "boolValue",
        "arrayValue",
    ):
        if key in data:
            return data[key]
    return None


def attributes(data: dict) -> dict:
    return {entry.get("key", ""): value(entry) for entry in data.get("attributes", [])}


def verify_redaction(path: pathlib.Path, documents: list[dict]) -> None:
    if b"ABC123" in path.read_bytes():
        fail("artifact redaction failed: telemetry contains a seeded cargo identifier")

    def walk(value):
        if isinstance(value, dict):
            attribute_key = value.get("key")
            if isinstance(attribute_key, str) and attribute_key.lower() in FORBIDDEN_ATTRIBUTES:
                fail(
                    "artifact redaction failed: telemetry contains forbidden field "
                    f"{attribute_key}"
                )
            for key, child in value.items():
                if key.lower() in FORBIDDEN_ATTRIBUTES:
                    fail(f"artifact redaction failed: telemetry contains forbidden field {key}")
                yield from walk(child)
        elif isinstance(value, list):
            for child in value:
                yield from walk(child)

    for document in documents:
        for _ in walk(document):
            pass


def resource_spans(document: dict) -> Iterator[tuple[str, str, dict]]:
    for resource_group in document.get("resourceSpans", []):
        resource = attributes(resource_group.get("resource", {}))
        service = resource.get("service.name")
        instance = resource.get("service.instance.id")
        for scope_group in resource_group.get("scopeSpans", []):
            for span in scope_group.get("spans", []):
                yield service or "", instance or "", span


def header_value(span_attributes: dict) -> str | None:
    for key in (
        "http.request.header.x_ci_request_id",
        "http.request.header.x-ci-request-id",
        "http.request.header.x_ci_request_id.0",
    ):
        candidate = span_attributes.get(key)
        if isinstance(candidate, dict) and "values" in candidate:
            candidate = [value(entry) for entry in candidate["values"]]
        if isinstance(candidate, list) and candidate:
            candidate = candidate[0]
        if candidate == REQUEST_ID:
            return candidate
    return None


def verify_trace(
    path: pathlib.Path,
    transcripts: list[dict],
    access_log: pathlib.Path,
    transcript_path: pathlib.Path | None = None,
) -> set[str]:
    trace_records = records(path, "trace export")
    verify_redaction(path, trace_records)
    spans = [
        (service, instance, span, attributes(span))
        for document in trace_records
        for service, instance, span in resource_spans(document)
    ]
    access = access_log.read_text() if access_log.is_file() else ""
    transcript_by_kind = {entry.get("kind"): entry for entry in transcripts}
    server_instances = set()

    for kind, request in REQUESTS.items():
        transcript = transcript_by_kind.get(kind)
        if not transcript:
            fail(f"broken correlation: request transcript is missing {kind}")
        if (
            transcript.get("request_id") != REQUEST_ID
            or transcript.get("trace_id") != request["trace_id"]
            or transcript.get("path") != request["path"]
            or transcript.get("status") != request["status"]
        ):
            fail(f"broken correlation: transcript does not match {kind} request")

        matches = []
        for service, instance, span, span_attributes in spans:
            if (
                service == "cargo-tracker"
                and instance
                and span.get("traceId", "").lower() == request["trace_id"]
                and header_value(span_attributes) == REQUEST_ID
                and span.get("kind") in ("SPAN_KIND_SERVER", 2, "2")
            ):
                matches.append((instance, span, span_attributes))
        if len(matches) != 1:
            fail(f"broken correlation: expected one server span for {kind} request")
        instance, span, span_attributes = matches[0]
        server_instances.add(instance)
        span_id = span.get("spanId", "")
        if not re.fullmatch(r"[0-9a-f]{16}", span_id) or set(span_id) == {"0"}:
            fail(f"broken correlation: {kind} span has no valid span identifier")
        transcript["server_span_id"] = span_id

        method = span_attributes.get("http.request.method", span_attributes.get("http.method"))
        path_value = span_attributes.get("url.path", span_attributes.get("http.target", ""))
        status = span_attributes.get(
            "http.response.status_code", span_attributes.get("http.status_code")
        )
        if method != "GET" or request["path"] not in str(path_value):
            fail(f"broken correlation: {kind} span has no matching HTTP operation")
        try:
            status = int(status)
        except (TypeError, ValueError):
            fail(f"invalid request lacks diagnostic signal: {kind} span has no HTTP status")
        if status != request["status"]:
            fail(f"invalid request lacks diagnostic signal: {kind} span status was {status}")
        start = span.get("startTimeUnixNano")
        end = span.get("endTimeUnixNano")
        if not span.get("name") or not start or not end:
            fail(f"missing telemetry: {kind} span has no operation or timestamps")
        if int(end) < int(start):
            fail(f"missing telemetry: {kind} span has an invalid timestamp interval")
        timestamp = transcript.get("timestamp", "")
        try:
            datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            fail(f"broken correlation: {kind} transcript has no valid UTC timestamp")

        traceparent = (
            f"00-{request['trace_id']}-"
            f"{transcript.get('parent_span_id', '')}-01"
        )
        matching_access = [
            line
            for line in access.splitlines()
            if REQUEST_ID in line and traceparent in line and request["path"] in line
        ]
        if not any(
            re.search(rf"\s{request['status']}\s", line)
            and re.search(r"\d{2}/[A-Za-z]{3}/\d{4}:", line)
            for line in matching_access
        ):
            fail(f"broken correlation: Liberty access log lacks the {kind} request identity")
        if kind == "success":
            if status < 200 or status >= 300:
                fail("successful request trace did not report a 2xx status")
        elif status < 400:
            fail("invalid request lacks diagnostic signal: expected an HTTP error status")
    if transcript_path is not None:
        transcript_path.write_text(
            "".join(json.dumps(entry, separators=(",", ":")) + "\n" for entry in transcripts)
        )
    return server_instances


def verify_metrics(path: pathlib.Path, server_instances: set[str]) -> None:
    documents = records(path, "runtime metrics export")
    verify_redaction(path, documents)
    for document in documents:
        for resource_group in document.get("resourceMetrics", []):
            resource = attributes(resource_group.get("resource", {}))
            service = resource.get("service.name")
            instance = resource.get("service.instance.id")
            if service != "cargo-tracker" or instance not in server_instances:
                continue
            for scope_group in resource_group.get("scopeMetrics", []):
                for metric in scope_group.get("metrics", []):
                    if not metric.get("name", "").startswith(("jvm.", "process.runtime.jvm.")):
                        continue
                    for data in ("gauge", "sum", "histogram", "exponentialHistogram", "summary"):
                        if metric.get(data, {}).get("dataPoints"):
                            return
    fail("missing telemetry: no non-empty JVM runtime metric samples were exported")


def verify_transcript(path: pathlib.Path) -> list[dict]:
    content = records(path, "request transcript")
    if len(content) != len(REQUESTS):
        fail("broken correlation: expected exactly two metadata-only request records")
    return content


def verify_agent(agent: pathlib.Path, expected_hash: str) -> None:
    import hashlib

    if not agent.is_file():
        fail("incompatible instrumentation: pinned OpenTelemetry Java agent is missing")
    digest = hashlib.sha256(agent.read_bytes()).hexdigest()
    if digest != expected_hash:
        fail("incompatible instrumentation: pinned OpenTelemetry Java agent checksum mismatch")


def self_test() -> None:
    import tempfile

    def expect_error(label: str, expected: str, operation) -> None:
        try:
            operation()
        except (OSError, ValueError, TypeError, KeyError) as error:
            if expected not in str(error):
                fail(f"{label} negative control produced the wrong diagnostic: {error}")
            print(f"{label}: explicit diagnostic verified")
            return
        fail(f"{label} negative control unexpectedly passed")

    with tempfile.TemporaryDirectory() as temporary:
        root = pathlib.Path(temporary)
        expect_error(
            "incompatible instrumentation",
            "incompatible instrumentation",
            lambda: verify_agent(root / "missing-agent.jar", "0" * 64),
        )
        expect_error(
            "missing telemetry",
            "missing telemetry",
            lambda: records(root / "missing-traces.json", "trace export"),
        )
        unsafe_traces = root / "unsafe-traces.json"
        unsafe_traces.write_text('{"resourceSpans":[],"cargo":"ABC123"}\n')
        expect_error(
            "artifact redaction",
            "artifact redaction failed",
            lambda: verify_trace(unsafe_traces, [], root / "missing-access.log"),
        )
        unsafe_exemplars = root / "unsafe-exemplars.json"
        unsafe_exemplars.write_text(
            json.dumps(
                {
                    "resourceMetrics": [
                        {
                            "scopeMetrics": [
                                {
                                    "metrics": [
                                        {
                                            "name": "jvm.memory.used",
                                            "histogram": {
                                                "dataPoints": [
                                                    {
                                                        "exemplars": [
                                                            {
                                                                "filteredAttributes": [
                                                                    {
                                                                        "key": "url.query",
                                                                        "value": {
                                                                            "stringValue": "trackingId=<REDACTED>"
                                                                        },
                                                                    }
                                                                ]
                                                            }
                                                        ]
                                                    }
                                                ]
                                            },
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            )
            + "\n"
        )
        expect_error(
            "unsafe exemplar redaction",
            "artifact redaction failed",
            lambda: verify_metrics(unsafe_exemplars, set()),
        )
        trace_document = {"resourceSpans": []}
        transcript = []
        access_rows = []
        for kind, request in REQUESTS.items():
            parent_span_id = "aaaaaaaaaaaaaaaa" if kind == "success" else "bbbbbbbbbbbbbbbb"
            traceparent = f"00-{request['trace_id']}-{parent_span_id}-01"
            trace_document["resourceSpans"].append(
                {
                    "resource": {
                        "attributes": [
                            {"key": "service.name", "value": {"stringValue": "cargo-tracker"}},
                            {
                                "key": "service.instance.id",
                                "value": {"stringValue": "self-test-instance"},
                            },
                        ]
                    },
                    "scopeSpans": [
                        {
                            "spans": [
                                {
                                    "traceId": request["trace_id"],
                                    "spanId": "3333333333333333"
                                    if kind == "success"
                                    else "4444444444444444",
                                    "name": f"GET {request['path']}",
                                    "kind": "SPAN_KIND_SERVER",
                                    "startTimeUnixNano": "1790812800000000000",
                                    "endTimeUnixNano": "1790812800001000000",
                                    "attributes": [
                                        {
                                            "key": "http.request.header.x_ci_request_id",
                                            "value": {
                                                "arrayValue": {
                                                    "values": [
                                                        {"stringValue": REQUEST_ID}
                                                    ]
                                                }
                                            },
                                        },
                                        {
                                            "key": "http.request.method",
                                            "value": {"stringValue": "GET"},
                                        },
                                        {
                                            "key": "url.path",
                                            "value": {"stringValue": request["path"]},
                                        },
                                        {
                                            "key": "http.response.status_code",
                                            "value": {"intValue": str(request["status"])},
                                        },
                                    ],
                                }
                            ]
                        }
                    ],
                }
            )
            transcript.append(
                {
                    "timestamp": "2026-10-01T00:00:00Z",
                    "kind": kind,
                    "request_id": REQUEST_ID,
                    "path": request["path"],
                    "status": request["status"],
                    "trace_id": request["trace_id"],
                    "parent_span_id": parent_span_id,
                }
            )
            access_rows.append(
                f'[01/Oct/2026:00:00:00 +0000] "GET {request["path"]} HTTP/1.1" '
                f'{request["status"]} {REQUEST_ID} {traceparent}'
            )
        traces_path = root / "traces.json"
        traces_path.write_text(json.dumps(trace_document) + "\n")
        access_path = root / "access.log"
        access_path.write_text("\n".join(access_rows) + "\n")
        expect_error(
            "broken correlation",
            "broken correlation",
            lambda: verify_trace(traces_path, [], access_path),
        )
        invalid_span = trace_document["resourceSpans"][1]["scopeSpans"][0]["spans"][0]
        invalid_span["attributes"] = [
            attribute
            for attribute in invalid_span["attributes"]
            if attribute["key"] != "http.response.status_code"
        ]
        traces_path.write_text(json.dumps(trace_document) + "\n")
        expect_error(
            "invalid request lacks diagnostic signal",
            "invalid request lacks diagnostic signal",
            lambda: verify_trace(traces_path, transcript, access_path),
        )
        metrics_path = root / "metrics.json"
        metrics_path.write_text(
            json.dumps(
                {
                    "resourceMetrics": [
                        {
                            "resource": {
                                "attributes": [
                                    {
                                        "key": "service.name",
                                        "value": {"stringValue": "cargo-tracker"},
                                    },
                                    {
                                        "key": "service.instance.id",
                                        "value": {"stringValue": "self-test-instance"},
                                    },
                                ]
                            },
                            "scopeMetrics": [
                                {
                                    "metrics": [
                                        {
                                            "name": "jvm.memory.used",
                                            "sum": {"dataPoints": [{"asInt": "100"}]},
                                        }
                                    ]
                                }
                            ],
                        }
                    ]
                }
            )
            + "\n"
        )
        verify_metrics(metrics_path, {"self-test-instance"})
    print("observability negative-control self-test passed")


def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
        return
    if len(sys.argv) == 4 and sys.argv[1] == "--verify-agent":
        try:
            verify_agent(pathlib.Path(sys.argv[2]), sys.argv[3])
        except (OSError, ValueError) as error:
            print(str(error), file=sys.stderr)
            raise SystemExit(1) from error
        print("pinned OpenTelemetry Java agent checksum verified")
        return
    if len(sys.argv) != 4:
        raise SystemExit(
            "usage: verify-observability.py <telemetry-directory> "
            "<transcript.jsonl> <liberty-access-log>"
        )
    telemetry = pathlib.Path(sys.argv[1])
    transcript_path = pathlib.Path(sys.argv[2])
    access_log_path = pathlib.Path(sys.argv[3])
    try:
        transcript = verify_transcript(transcript_path)
        server_instances = verify_trace(
            telemetry / "traces.json",
            transcript,
            access_log_path,
            transcript_path,
        )
        verify_metrics(telemetry / "metrics.json", server_instances)
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from error
    print("observability verification passed: 2 correlated server spans and JVM metrics")


if __name__ == "__main__":
    main()
