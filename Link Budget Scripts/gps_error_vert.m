close all;
clear;

R = physconst("EarthRadius");

sat_height_m = 500e3;

figure()
hold on

% positional error from GPS [m]
d_err_list = [0.1,1,10];

for d_err=d_err_list
    gamma_err_from_arc_rad = d_err/R;
    gamma_err_from_hor_rad = atan2(d_err,R);
    
    el_max = pi/2-obtuse_angle(gamma_err_from_arc_rad, R, R+sat_height_m);
    
    el_rad = deg2rad(linspace(10,90,801));
    
    beta_err = nan(size(el_rad));
    
    % Satellite Elevation = 90
    inteval_ids = el_rad-pi/2<eps(pi);

    r_err = sqrt(R^2+(R+sat_height_m).^2-2*R*(R+sat_height_m)*cos(gamma_err_from_arc_rad));
    
    nu_err = acos((r_err.^2+R^2-(sat_height_m+R).^2)./(2*r_err.*R));
    
    beta_err(inteval_ids) = pi-nu_err;
    
    scatter(90,rad2deg(beta_err(inteval_ids)), "HandleVisibility","off")
    
    % Satellite Elevation <90 & > el_max
    interval_ids = (el_rad<pi/2) & (el_rad>=el_max);
    interval_el_rad = el_rad(interval_ids);
    r = sqrt((R*cos(interval_el_rad)).^2+(R+sat_height_m).^2-R^2)-R*cos(interval_el_rad);
    r_err = sqrt(d_err.^2 + r.^2 - 2 * d_err.*r .* cos(interval_el_rad));
    
    nu_err = acos((R^2+r_err.^2-(R+sat_height_m).^2)./(2*R*r_err));
    
    beta_err(interval_ids) = pi-nu_err+(pi/2-interval_el_rad);
    
    % Satellite Elevation <0 & < el_max
    interval_ids = el_rad<el_max;
    interval_el_rad = el_rad(interval_ids);
    
    r = sqrt((R*cos(interval_el_rad)).^2+(R+sat_height_m).^2-R^2)-R*cos(interval_el_rad);
    [alpha_rad, gamma_rad, range_m, ground_arc_m] = sat_geometry(interval_el_rad, sat_height_m, R);
    
    gamma1 = gamma_rad-gamma_err_from_arc_rad;
    alpha1 = pi-(gamma1+interval_el_rad+pi/2);
    h1 = sin(interval_el_rad+pi/2)./sin(alpha1)*R-R;
    r2 = sqrt(R^2+(R+sat_height_m).^2-2*R*(R+sat_height_m)*cos(gamma1));
    beta_err(interval_ids) = asin((sat_height_m-h1)./r2.*sin(pi-alpha1));
    
    plot(rad2deg(el_rad),rad2deg(beta_err), "DisplayName",sprintf("GPS err: %.1f m", d_err))
end

yline(0.002,"HandleVisibility","off")
text(80,0.003,"0.002")

yscale("log")
xlabel("Sat. Elevation [deg]")
ylabel("Pointing Error [deg]")

legend()
grid on


function [alpha_rad, gamma_rad, range_m, ground_arc_m] = sat_geometry(el_rad, sat_alt_m, R)
% SAT_GEOMETRY  Earth-satellite link geometry from elevation angle.
%
%   [alpha, gamma, range, ground_arc] = sat_geometry(el_rad, sat_alt_m, R)
%
%   Inputs:
%       el_rad      - Elevation angle(s) [rad], in (0, pi/2]
%       sat_alt_m   - Satellite altitude [m], positive scalar
%       R           - Earth radius [m] (default: physconst('EarthRadius'))
%
%   Outputs:
%       alpha_rad   - Nadir angle at satellite [rad]
%       gamma_rad   - Earth central angle [rad]
%       range_m     - Slant range [m]
%       ground_arc_m- Ground-range arc length [m]

    if nargin < 3
        R = physconst('EarthRadius');
    end

    % --- Input validation ---
    assert(isscalar(sat_alt_m) && sat_alt_m > 0, ...
        'sat_geometry:badAlt', 'sat_alt_m must be a positive scalar.');
    assert(isscalar(R) && R > 0, ...
        'sat_geometry:badR', 'R must be a positive scalar.');
    assert(all(el_rad > 0 & el_rad <= pi/2, 'all'), ...
        'sat_geometry:badEl', 'el_rad must be in (0, pi/2].');

    Rs = R + sat_alt_m;

    alpha_rad = asin((R ./ Rs) .* sin(el_rad + pi/2));
    gamma_rad = pi/2 - (alpha_rad + el_rad);

    % Slant range via sine rule; handle zenith (el = pi/2) separately
    zenith = abs(el_rad - pi/2) < eps(pi);
    range_m = sin(gamma_rad) ./ sin(el_rad + pi/2) .* Rs;
    range_m(zenith) = sat_alt_m;

    ground_arc_m = R .* gamma_rad;
end

function el_max = obtuse_angle(gamma_rad, R, R_h)
% OBTUSE_ANGLE  Find the obtuse angle B opposite side b.
%   A - known acute angle (rad), between sides b and c
%   b - side opposite the desired obtuse angle (longest side)
%   c - the other adjacent side
%
%   Returns B in radians.

el_max = atan2(R * sin(gamma_rad), R_h - R * cos(gamma_rad));

% atan2 returns (-pi, pi]; if negative, wrap to positive
if el_max < 0
    el_max = el_max + pi;
end

end