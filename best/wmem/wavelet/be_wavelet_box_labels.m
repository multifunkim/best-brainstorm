function Labels = be_wavelet_box_labels(WData, OPTIONS, obj)
% BE_WAVELET_BOX_LABELS describes every time-frequency box of a wavelet
% decomposition: where it sits in the coefficient matrix, which scale it
% belongs to, when it happens and how much power it carries.
%
% This function ONLY labels. It does not select, threshold, sort or fuse.
%
%   INPUTS:
%       -   WData   :   wavelet transform of ONE modality (Nsensors x Nsamples_extended),
%                       with the coarsest (approximation) coefficients zeroed
%       -   OPTIONS :   options structure. Uses:
%                           OPTIONS.automatic.scales          (set by be_discrete_wavelet_transform)
%                           OPTIONS.automatic.sampling_rate
%       -   obj     :   structure with
%                           obj.t0                  : time of first true sample
%                           obj.info_extension.start: first true sample in the extended data
%                           obj.info_extension.end  : last  true sample in the extended data
%
%   OUTPUTS:
%       -   Labels  :   structure of row vectors, one entry per box, boxes
%                       ordered by scale (j = 1, 2, ...) then by position k:
%           .index  : column index of the box in WData (extended data)
%           .scale  : scale j
%           .k      : position of the box within its scale
%           .time   : time of the box centre (s)
%           .power  : mean power over sensors of the coefficient
%           .win_l  : left  edge of the box, in true (non-extended) samples
%           .win_r  : right edge of the box, in true (non-extended) samples
%
%% ==============================================
% Copyright (C) 2012 - LATIS Team
%
%  Authors: LATIS, 2012
%
%% ==============================================
% License 
%
% BEst is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    BEst is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with BEst. If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------

nbl = size(OPTIONS.automatic.scales,2);   % number of scales
nbb = size(WData,2);                      % number of time samples (extended)
nbc = size(WData,1);                      % number of channels
fs  = OPTIONS.automatic.sampling_rate;

ext_start   = obj.info_extension.start;
ext_end     = obj.info_extension.end;
t0_extended = obj.t0 - (ext_start-1)/fs;  % time t0 in the extended data

index = [];
scale = [];
k     = [];
time  = [];
power = [];

for j = 1:nbl
    % Scale j occupies columns nbb/2^j+1 : nbb/2^(j-1).
    % 2 boxes are dropped on each side (edge effects).
    deb = 1 + nbb/2^j + 2;
    fin = nbb/2^(j-1) - 2;
    kj  = (deb-nbb/2^j):(fin-nbb/2^j);

    power = [power, sum(abs(WData(:,deb:fin)).^2,1)/nbc];
    index = [index, deb:fin];
    scale = [scale, j*ones(1,length(deb:fin))];
    k     = [k,     kj];
    time  = [time,  t0_extended + (2^(j-1))*(2*kj-1)/fs];
end

% Box edges in the true data samples (not extended)
win_l = max((k-1).*(2.^scale)+1, ext_start) - ext_start + 1;
win_r = min( k   .*(2.^scale),   ext_end)   - ext_start + 1;

Labels = struct('index', index, ...
                'scale', scale, ...
                'k',     k, ...
                'time',  time, ...
                'power', power, ...
                'win_l', win_l, ...
                'win_r', win_r);

end