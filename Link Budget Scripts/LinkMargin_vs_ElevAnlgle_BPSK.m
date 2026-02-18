clear, close all;
%addpath(genpath('./functions'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VARIABLES
% ---- Constants ----
K_boltz = physconst('boltzman');
T0      = 290;
c       = physconst('LightSpeed');
%% ---- Geographic Specifications----
alt_m  = 600e3;            % [m] 
inclination_angle = 45; %51.6;   %[degrees]
% GS height: 18+12.192+3 is height above sea level (MSL)
h_msl_m = 18.12; 
h_bldg_m = 12.192;
h_mast_m = 3;
h_gs_tot_m = h_msl_m + h_bldg_m + h_mast_m;
GS_pos_m      = (6371000 + h_gs_tot_m); %m (6371000 is Earth average radius in meters, the rest are MSL of location+ building height +antenna mast height)

gs_lat   = 42.3378054237531; % Egan Roof
gs_long = -71.08885435; % Egan Roof
Elev = linspace(0,90,91);

%% ---- RF Hardware Parameters ----
freq_Hz       = 225 * 1e9;
M = 2; %BPSK
targetBitRate = 1e8;
targetBER     = 1e-4;       
rolloff       = 0.3;
BW       = 1.30e8;            %[Hz] 130 MHz = 100 Mbps
atmType = "InterpSummer"; % ["Summer 45","Winter 45","Annual 15","InterpWinter","InterpSummer", or "AndrewsBostonProfile"];
%% ---- Hardware Performance----
% System Gains and Output Power
sat_tx        = 24.98;   % [dBm]
geff_satAnt   = 38; %     % Updated value (was 44 originally): true effective gain acc to Albert after all antenna specific losses. [dBi]
geff_gsAnt = [69,70,71,72,73,74,75];   % [dBi]

% Radio NF
NF       = 7;            %[dB]

% Additional System Losses
GS_feed_network_loss = 2.48;
GS_radome = 1.5;
Imp_loss = 1.15; % Implementation loss (added per UNP feedback)

loss_adt = GS_feed_network_loss + GS_radome + Imp_loss; 

%% ---- Pointing Losses ----
gs_ptg_error_loss = 3.01; %[dB]
sat_ptg_error_loss = 0.62; %[dB]
polarization_miss_match_loss = 0.033; %[dB]
l_ptg = gs_ptg_error_loss+sat_ptg_error_loss+polarization_miss_match_loss;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRECOMPUTATIONS

% ---- Atmosphere ----
hstep    = 0.1;            % [km]
slant_dist_m  = sqrt(GS_pos_m.^2 .* sind(Elev).^2 + 2*GS_pos_m*alt_m + alt_m.^2) ...
              - GS_pos_m .* sind(Elev)      ;           % [m]

% ---- GS Noise Profiles ----
[T1,P1,e1]     = atmProfile(h_gs_tot_m/1000,"Annual 15");
[T2S,P2S,e2S]  = atmProfile(h_gs_tot_m/1000,"Summer 45");
[Tgs_s,~,~]     = InterpAtm({T1,P1,e1},{T2S,P2S,e2S},gs_lat);
[T2W,P2W,e2W]  = atmProfile(h_gs_tot_m/1000,"Winter 45");
[Tgs_w,~,~]     = InterpAtm({T1,P1,e1},{T2W,P2W,e2W},gs_lat);
T_gs_s = max(Tgs_s, 300);

% ---- System noise temperatures for seasonal cases ----
Tsys_s = (10^(NF/10)-1)*T0 + T_gs_s;
Tsys_w = (10^(NF/10)-1)*T0 + Tgs_w;

% ---- BPSK required Eb/N0 for target BER ----
b = log2(M);
BER_function = @(x) berawgn(x,"psk",M,"nondiff") - targetBER;
EbNo_min_dB  = fzero(BER_function,10)  ; % good initial guess

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FORMATTING
figure
hold on
xlabel('Elevation Angle [deg]');
ylabel('Link Margin (dB)');
title(sprintf('Link Margin vs Elevation Angle at %.0f GHz', freq_Hz*1e-9));
xlim([10,90]); ylim([-40,100]); 
grid on;
legend;
colors = [
    0.1216 0.4667 0.7059;   % Blue
    1.0000 0.4980 0.0549;   % Orange
    0.1725 0.6275 0.1725;   % Green
    0.8392 0.1529 0.1569;   % Red
    0.5804 0.4039 0.7412;   % Purple
    0.5490 0.3373 0.2941;   % Brown
    0.8902 0.4667 0.7608;   % Pink
    0.4980 0.4980 0.4980;   % Gray
    0.7373 0.7412 0.1333;   % Olive
];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN LOOP (per atmosphere)

for k = 1:numel(geff_gsAnt)
    % Atmospheric absorption along slant path
    l_abs = absLossSlant(alt_m/1000, freq_Hz*1e-9, Elev, hstep, (h_gs_tot_m)/1000, atmType, gs_lat); % [dB]
    % Received power vs elevation (dBm)
    p_rx_dBm = zeros(size(Elev));
    for j = 1:numel(Elev)
        p_rx_dBm(j) = linkBudget_Simplified(sat_tx, geff_satAnt, geff_gsAnt(k), freq_Hz, slant_dist_m(j), l_abs(1,1,j), l_ptg, loss_adt); % result is in dBm
    end
   
     % Noise floor (dBm), SNR, Eb/N0, Link Margin
     Tsys = Tsys_s;
     Pnf_dBm    = 10*log10(K_boltz*Tsys*BW) + 30;        %dB
     snr_dB     = p_rx_dBm  - Pnf_dBm   ;                %dB

     %Commented out for SNR to understand pure tone behavior
     EbNo_dB    = snr_dB + 10*log10((1+rolloff)/b) ;     %dB
     linkMargin = EbNo_dB - EbNo_min_dB  ;              %dB

    % ---------- Figure 1: plot link margin for each gain value ----------
    name1 = sprintf('%.1f dBi',geff_gsAnt);

    plot(Elev, linkMargin, 'LineWidth', 1.5,'Color', colors(k,:), ...
        'DisplayName', sprintf('%.2f dBi', geff_gsAnt(k)));
     if k == numel(geff_gsAnt)
         hline = yline(3, 'Color', 'black', 'LineStyle','--', ...
             'LineWidth', 3, 'DisplayName', '3 dB');
     end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%