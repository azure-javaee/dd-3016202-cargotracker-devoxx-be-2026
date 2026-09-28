1. Get https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026 to a stable state with the cargotracker content moved inside a top level `demo` directory.
   1. Everything repeatably builds and runs from the command line locally.
   
      - ✅ **Completed** darwin-arm64
      - ✅ **Completed** linux-x64
      - ✅ **Completed**win32-x64
      
   2. ✅ **Completed** All CI is repeatably green.
   
      - https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36183229399
      
      - https://github.com/edburns/dd-3016202-cargotracker-devoxx-be-2026/actions/runs/36182474700
      

2. Create two topic branches from `edburns/dd-3016202-cargotracker-devoxx-be-2026-01`:

   1. `edburns/dd-3016202-cargotracker-devoxx-be-2026-control`
   2. `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`
3. Non-demo related preparation iterates on `edburns/dd-3016202-cargotracker-devoxx-be-2026-01`.
4. Demo related preparation iterates on `edburns/dd-3016202-cargotracker-devoxx-be-2026-experiment`.
5. No changes on `edburns/dd-3016202-cargotracker-devoxx-be-2026-control`.
