clear; close all;

%% ========================================================================
%  Load configuration
%  ========================================================================
cfg = jsondecode(fileread('config.json'));

%% ========================================================================
%  Constants
%  ========================================================================
K_boltz = physconst('Boltzman');
T0      = 290;
c       = physconst('LightSpeed');

%% ========================================================================
%  Config parameters
%  ========================================================================
alt_km       = cfg.orbit.alt_km;
alt_m       = alt_km*1e3;
sat_tx      = cfg.satellite.tx_power_dBm;
geff_satAnt = cfg.satellite.antenna_gain_dBi;

M         = cfg.modulation.M;
targetBER = cfg.modulation.target_BER;
b         = log2(M);

loss_adt = cfg.losses.GS_feed_network_dB ...
         + cfg.losses.GS_radome_dB ...
         + cfg.losses.implementation_dB;

l_ptg = cfg.losses.gs_pointing_error_dB ...
      + cfg.losses.sat_pointing_error_dB ...
      + cfg.losses.polarization_mismatch_dB;

atmType = cfg.atmosphere.type;

%% ========================================================================
%  In-script parameters
%  ========================================================================

% Ground station
H_abv_Sea  = 18 + 12.192 + 3;          % [m] MSL + building + mast
GS_pos_m   = 6371000 + H_abv_Sea;
gs_lat     = 42.3378054237531;          % Egan Roof
gs_long    = -71.08885435;              % Egan Roof
Elev       = linspace(0, 90, 91);

% RF
freq_Hz       = 2.25e11;
targetBitRate = 1e8;
rolloff       = 0.3;
BW            = 1.30e8;                 % [Hz] 130 MHz

% Receiver
NF = 7;                                 % [dB]

% GS antenna gain sweep
geff_gsAnt = [69, 70, 71, 72, 73, 74, 75];

% Atmosphere integration
hstep = 0.1;                            % [km]

%% ========================================================================
%  Precomputations
%  ========================================================================

% Slant distance
slant_dist_m = sqrt(GS_pos_m.^2 .* sind(Elev).^2 ...
             + 2 * GS_pos_m * alt_m + alt_m.^2) ...
             - GS_pos_m .* sind(Elev);

% GS noise profiles
[T1,  P1,  e1]  = atmProfile(H_abv_Sea, "Annual 15");
[T2S, P2S, e2S] = atmProfile(H_abv_Sea, "Summer 45");
[Tgs_s, ~, ~]   = InterpAtm({T1, P1, e1}, {T2S, P2S, e2S}, gs_lat);
[T2W, P2W, e2W] = atmProfile(H_abv_Sea, "Winter 45");
[Tgs_w, ~, ~]   = InterpAtm({T1, P1, e1}, {T2W, P2W, e2W}, gs_lat);
T_gs_s = max(Tgs_s, 300);

% System noise temperatures
Tsys_s = (10^(NF / 10) - 1) * T0 + T_gs_s;
Tsys_w = (10^(NF / 10) - 1) * T0 + Tgs_w;

% Required Eb/N0 for target BER
BER_fn      = @(x) berawgn(x, "psk", M, "nondiff") - targetBER;
EbNo_min_dB = fzero(BER_fn, 10);

%% ========================================================================
%  Figure setup
%  ========================================================================
colors = [
    0.1216 0.4667 0.7059
    1.0000 0.4980 0.0549
    0.1725 0.6275 0.1725
    0.8392 0.1529 0.1569
    0.5804 0.4039 0.7412
    0.5490 0.3373 0.2941
    0.8902 0.4667 0.7608
    0.4980 0.4980 0.4980
    0.7373 0.7412 0.1333
];

figure; hold on; grid on;
xlabel('Elevation Angle [deg]');
ylabel('Link Margin (dB)');
title(sprintf('Link Margin vs Elevation Angle at %.0f GHz', freq_Hz * 1e-9));
xlim([10, 90]);
ylim([-40, 100]);

%% ========================================================================
%  Main sweep over GS antenna gains
%  ========================================================================
for k = 1:numel(geff_gsAnt)

    l_abs = absLossSlant(alt_m / 1000, freq_Hz * 1e-9, Elev, ...
                         hstep, H_abv_Sea / 1000, atmType, gs_lat);

    p_rx_dBm = zeros(size(Elev));
    for j = 1:numel(Elev)
        p_rx_dBm(j) = linkBudget_Simplified( ...
            sat_tx, geff_satAnt, geff_gsAnt(k), ...
            freq_Hz, slant_dist_m(j), l_abs(1,1,j), l_ptg, loss_adt);
    end

    Tsys       = Tsys_s;
    Pnf_dBm   = 10 * log10(K_boltz * Tsys * BW) + 30;
    snr_dB     = p_rx_dBm - Pnf_dBm;
    EbNo_dB    = snr_dB + 10 * log10((1 + rolloff) / b);
    linkMargin = EbNo_dB - EbNo_min_dB;

    plot(Elev, linkMargin, 'LineWidth', 1.5, ...
         'Color', colors(k, :), ...
         'DisplayName', sprintf('%.1f dBi', geff_gsAnt(k)));

    if k == numel(geff_gsAnt)
        yline(3, 'Color', 'black', 'LineStyle', '--', ...
              'LineWidth', 3, 'DisplayName', '3 dB');
    end
end

legend('Location', 'best');