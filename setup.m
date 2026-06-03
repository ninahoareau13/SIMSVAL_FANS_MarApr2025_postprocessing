%% setup.m — Configure toolbox paths for SIMSVAL_FANS_MarApr2025_postprocessing
%
% Run this script once before using the processing pipeline.
% It checks for required toolboxes and adds them to the MATLAB path.
%
% Usage:
%   run('setup.m')   % from the repo root
%
% Required toolboxes (download links in README.md):
%   - RSKtools v3.6   : https://github.com/RBRglobal/rbr-rsktools
%   - TEOS-10 GSW     : http://www.teos-10.org/software.htm
%   - cmocean         : https://github.com/chadagreene/cmocean  (optional)

fprintf('\n=== SIMSVAL_FANS_MarApr2025 — Toolbox Setup ===\n\n')

%% ── 1. RSKtools ──────────────────────────────────────────────────────────
rsktools_path = input('Path to RSKtools folder (rbr-rsktools/): ', 's');
if ~isempty(rsktools_path) && exist(rsktools_path, 'dir')
    addpath(rsktools_path);
    % Test
    if exist('RSKopen', 'file')
        fprintf('  [OK] RSKtools found\n')
    else
        warning('RSKopen not found in %s — check the path.', rsktools_path)
    end
else
    warning('RSKtools path not found: %s', rsktools_path)
end

%% ── 2. TEOS-10 GSW ───────────────────────────────────────────────────────
gsw_path = input('Path to TEOS-10 GSW folder: ', 's');
if ~isempty(gsw_path) && exist(gsw_path, 'dir')
    addpath(gsw_path);
    addpath(fullfile(gsw_path, 'library'));
    addpath(fullfile(gsw_path, 'thermodynamics_from_t'));
    % Test
    if exist('gsw_sigma0', 'file')
        fprintf('  [OK] TEOS-10 GSW found\n')
    else
        warning('gsw_sigma0 not found in %s — check the path.', gsw_path)
    end
else
    warning('TEOS-10 path not found: %s', gsw_path)
end

%% ── 3. cmocean (optional) ────────────────────────────────────────────────
cmocean_path = input('Path to cmocean folder (leave empty to skip): ', 's');
if ~isempty(cmocean_path) && exist(cmocean_path, 'dir')
    addpath(cmocean_path);
    fprintf('  [OK] cmocean found\n')
end

%% ── 4. Save to MATLAB path permanently (optional) ───────────────────────
save_path = input('Save paths permanently to MATLAB path? (y/n): ', 's');
if strcmpi(save_path, 'y')
    savepath;
    fprintf('  [OK] Paths saved to pathdef.m\n')
end

fprintf('\nSetup complete. You can now run the pipeline scripts from scripts/\n')
fprintf('  Example: cd scripts; run(''proc_run_CTD_by_stations.m'')\n\n')
