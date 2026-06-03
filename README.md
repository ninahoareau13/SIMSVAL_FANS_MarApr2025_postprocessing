# SIMSVAL & FANS Mar–Apr 2025 — CTD Post-Processing Pipeline

MATLAB pipeline for post-processing CTD data from **RBR Concerto** sensors deployed during the **ARICE-PONANT 2025** spring campaigns (*SIMSVAL* and *FANS*) aboard R/V *Le Commandant Charcot* in western Greenland fjords (60.2–69.5°N).

This code produces the datasets published in:

> Hoareau et al. (2025). *Hydrographic CTD profiles capturing the onset of near-surface stratification in West Greenland fjords during the SIMSVAL and FANS spring 2025 campaigns.* Earth System Science Data. *(in preparation)*

---

## Dataset overview

| | Value |
|---|---|
| Region | Western Greenland fjords |
| Campaigns | SIMSVAL (Mar–Apr 2025) + FANS (Apr 2025) |
| Sensors | RBR Concerto³ 16 Hz (ICM-CSIC, S/N 237957) + RBR Concerto 2 Hz (PONANT) |
| L2 profiles | 73 (32 SIMSVAL + 41 FANS) |
| L0 profiles | 80 |

---

## Requirements

### MATLAB version
MATLAB R2021a or later.

### Required toolboxes

| Toolbox | Version tested | Download |
|---------|---------------|----------|
| **RSKtools** (RBR Ltd.) | v3.6 | [github.com/RBRglobal/rbr-rsktools](https://github.com/RBRglobal/rbr-rsktools) |
| **TEOS-10 GSW** | v3.06.16 | [teos-10.org/software.htm](http://www.teos-10.org/software.htm) |
| **cmocean** *(optional, figures only)* | v2.0 | [github.com/chadagreene/cmocean](https://github.com/chadagreene/cmocean) |

> **Note:** RSKtools requires `mksqlite` to read `.rsk` files. A compiled binary is included with RSKtools for Windows, macOS, and Linux.

### Path configuration

After downloading the toolboxes, run `setup.m` to configure your paths interactively:

```matlab
run('setup.m')
```

Or add them manually to your MATLAB path (edit paths to match your system):

```matlab
addpath('/path/to/rbr-rsktools/');
addpath('/path/to/teos10/');
addpath('/path/to/teos10/library/');
addpath('/path/to/cmocean/');   % optional
```

---

## Raw data

The raw `.rsk` files (RBR binary format) are **not distributed in this repository** due to file size.  
They are archived at PANGAEA: **doi:10.1594/PANGAEA.XXXXXXX** *(DOI to be assigned)*

Download the `.rsk` files and place them in:
```
scripts/RAW/raw_SIMSVAL/    ← SIMSVAL .rsk files (stations A, B, B1_val, C, I)
scripts/RAW/raw_FANS/       ← FANS .rsk files (ICM 16 Hz + PONANT 2 Hz)
```

---

## Repository structure

```
SIMSVAL_FANS_MarApr2025_postprocessing/
├── setup.m                           ← Configure MATLAB toolbox paths
├── README.md
├── LICENSE
├── CITATION.cff
├── scripts/
│   ├── proc_run_CTD_by_stations.m    ← Entry point: L2 per-station processing
│   ├── process_RBR_CTD.m             ← Core processing function
│   ├── proc_concat_SIMSVAL_matfile.m ← Concatenate SIMSVAL stations → .mat
│   ├── proc_concat_FANS_matfile.m    ← Concatenate FANS stations → .mat
│   ├── proc_run_CTD_concat_oceancasts_NetCDF_export.m  ← Final L2 NetCDF export
│   ├── raw_concat_SIMSVAL_matfile.m  ← Extract RAW SIMSVAL → .mat
│   ├── raw_concat_FANS_matfile.m     ← Extract RAW FANS → .mat
│   ├── raw_run_CTD_concat_oceancasts_NetCDF_export.m   ← Final L0 NetCDF export
│   ├── RSKtrim_soak.m                ← Soak detection (fixed_time / velocity)
│   ├── apply_QC_tests.m              ← 7 QC tests (SeaDataNet L20 flags)
│   └── export_netcdf.m               ← NetCDF-4 export (CF-1.8 / ACDD-1.3)
└── ancillary_data/
    ├── SSS_autosal.csv               ← AutoSal surface salinity water samples
    ├── station_coordinates.csv       ← Station lat/lon/campaign/frequency/fjord
    ├── Atmospheric_Data_SIMSVAL_hourlyMean.mat  ← FerryBox atmospheric data
    └── Atmospheric_Data_FANS_hourlyMean.mat     ← FerryBox atmospheric data
```

---

## How to run

All scripts use **relative paths** — run from the `scripts/` directory in MATLAB.

### L0 — Raw NetCDF (no processing)

```matlab
cd scripts/

% Step 1a — Extract raw SIMSVAL profiles from .rsk files
run('raw_concat_SIMSVAL_matfile.m')

% Step 1b — Extract raw FANS profiles from .rsk files
run('raw_concat_FANS_matfile.m')

% Step 2 — Combine and export → RAW_ARICE-2025_Greenland_CTD.nc
run('raw_run_CTD_concat_oceancasts_NetCDF_export.m')
```

### L2 — Processed NetCDF (main product)

```matlab
cd scripts/

% Step 1 — Process each station individually
% Edit proc_run_CTD_by_stations.m: set campaign_type ('SIMSVAL' or 'FANS')
% and station ('A', 'B', ..., '1A', '1B', ...) then run
run('proc_run_CTD_by_stations.m')

% Step 2a — Concatenate SIMSVAL → PROC_CTD_SIMSVAL_oceanCasts.mat
run('proc_concat_SIMSVAL_matfile.m')

% Step 2b — Concatenate FANS → PROC_CTD_FANS_oceanCasts.mat
run('proc_concat_FANS_matfile.m')

% Step 3 — Combine and export → PROC_CTD_ARICE_2025_Greenland_oceanCasts.nc
run('proc_run_CTD_concat_oceancasts_NetCDF_export.m')
```

---

## Processing pipeline (L2)

| Step | Operation | Notes |
|------|-----------|-------|
| 1 | Sea pressure = Pressure − Patm | Patm from FerryBox hourly means |
| 2 | A/D hold correction (`RSKcorrecthold`) | 16 Hz only |
| 3 | Despiking (`RSKdespike`) | 4σ, window 15 pts, direction *down* |
| 4 | C/T lag correction (`RSKalignchannel`) | 16 Hz only, cap ±2 scans |
| 5 | Smoothing (`RSKsmooth`) | window 5 pts |
| 6 | Depth + velocity derivation | |
| 7 | Soak removal (`RSKtrim_soak`) | fixed_time 20 s (5 s for 1A_1 and 7H_4) |
| 8 | Loop removal (`RSKremoveloops`) | threshold 0.1 m/s |
| 9 | Salinity + σ-θ derivation | TEOS-10 GSW |
| 10 | QC flags (`apply_QC_tests`) | 7 tests, SeaDataNet L20 |

---

## Output files

| File | Level | Profiles | Description |
|------|-------|----------|-------------|
| `RAW_ARICE-2025_Greenland_CTD.nc` | L0 | 80 | Raw data, no processing |
| `PROC_CTD_ARICE_2025_Greenland_oceanCasts.nc` | L2 | 73 | Processed + QC |

Both follow **CF-1.8 / ACDD-1.3** conventions, `featureType = "profile"`, 2D NaN-padded `(obs × profile)`.

---

## Authors

Nina Hoareau, Maria Sánchez, Júlia Crespin, Eva De-Andrés, Ferran Hernández-Macià, Carolina Gabarró, Marta Umbert

Institut de Ciències del Mar (ICM-CSIC), Barcelona, Spain — nhoareau@icm.csic.es

---

## License

MIT — see [LICENSE](LICENSE)

---

## Citation

If you use this code, please cite:

```bibtex
@software{hoareau2025_ctd_pipeline,
  author    = {Hoareau, Nina and Sánchez, Maria and Crespin, Júlia and
               De-Andrés, Eva and Hernández-Macià, Ferran and
               Gabarró, Carolina and Umbert, Marta},
  title     = {SIMSVAL and FANS Mar-Apr 2025 — CTD post-processing pipeline
               for RBR Concerto sensors},
  year      = {2025},
  version   = {1.0.0},
  publisher = {Zenodo},
  doi       = {10.5281/zenodo.XXXXXXX}
}
```
