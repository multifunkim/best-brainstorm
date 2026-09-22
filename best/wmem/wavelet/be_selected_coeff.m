function [OPTIONS] = be_selected_coeff(WM, obj, OPTIONS)
% BE_SELECTED_COEFF selects the wavelet coefficients to run the localization. 
% Only the boxes in the temporal interval of interest (TimeSegment) are kept
% (a box is kept if more than the half is included in the TimeSegment). 
% Only the boxes in the selected scale are kept.
% A maximum of 99% of the energy is kept. (except for nirs - keeping all the
% power)

% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% INPUTS:
%     - WM      : Data matrix (wavelet rep.) to be reconstructed using MEM
%     - obj     : Wavelet coefficients
%     - OPTIONS : Structure of parameters (described in be_main.m)
%
% OUTPUTS:
%     - Results : Structure
%          |- OPTIONS       : Keep track of parameters
%                           with the seleted wavelet coefficients
%
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

% === Initialize the parameters
nScale          = size(OPTIONS.automatic.scales,2);
nSampleExtended = size(WM{1}, 2);
nboxes          = nSampleExtended * ( 1 - 2^(-nScale));

% time t0 in the extended data
fs          = OPTIONS.automatic.sampling_rate;
t0_extended = obj.t0 - (obj.info_extension.start -1)/fs;

% === Table of selection
selected_values = cell(1, length(OPTIONS.mandatory.DataTypes));

% we keep 99pc of power for EEG/MEG, 100% of power for fNIRS
if any(strcmp(OPTIONS.mandatory.DataTypes,'NIRS'))
    pc_power    = 1;
else
    pc_power    = 0.99;
end

for iMod = 1 : length(OPTIONS.mandatory.DataTypes)

    selected_jk  = zeros(3, nboxes);
    t_kept       = zeros(1, nboxes);
    Wgfp         = zeros(1, nboxes);

    k = 1;
    for iScale=1:nScale
        
        scale_start     = 1+nSampleExtended/2^iScale + 2;
        scale_end       = nSampleExtended/2^(iScale-1) - 2;
        nSample         = 1+ scale_end - scale_start;   
        
        data = WM{iMod}(:, scale_start:scale_end);

        Wgfp(k:(k+nSample-1))             = mean(abs(data).^2, 1);
        selected_jk(1, k:(k+nSample-1))   = scale_start:scale_end;
        selected_jk(2, k:(k+nSample-1))   = iScale;
        selected_jk(3, k:(k+nSample-1))   = (scale_start-nSampleExtended/2^iScale):(scale_end-nSampleExtended/2^iScale);
        t_kept(k:(k+nSample-1))           = t0_extended+(2^(iScale-1))*(2*((scale_start-nSampleExtended/2^iScale):(scale_end-nSampleExtended/2^iScale))-1)/fs;

        k = k + nSample;
    end
    
    % Trim the array -- because of the +2, -2 on line 77, 78.
    Wgfp        = Wgfp(1:(k-1));
    selected_jk = selected_jk(:, 1:(k-1));
    t_kept      = t_kept(1:(k-1));

    % === selection (based on the power)
    [Wgfp_sorted, I] = sort(Wgfp,'descend');
    Ic               = find(cumsum(Wgfp_sorted)/sum(Wgfp) <= pc_power,1,'last');

    % what we finally keep:
    selected_jk = selected_jk(:, I(1:Ic));
    Wgfp        = Wgfp(I(1:Ic));
    t_kept      = t_kept(I(1:Ic));

    % MSP windows (in the true data samples -not extended-)
    win_l = max((selected_jk(3,:)-1).*(2.^selected_jk(2,:))+1,obj.info_extension.start) - obj.info_extension.start +1;
    win_r = min( selected_jk(3,:).*(2.^selected_jk(2,:)),obj.info_extension.end)        - obj.info_extension.start +1;

    % === what we keep, finally:
    OPTIONS.automatic.Modality(iMod).selected_jk = [selected_jk ; win_l ; win_r ; t_kept];
    selected_values{iMod} = [Wgfp ;  100 * Wgfp  / sum(Wgfp)];
end

% we keep the selection in the OPTIONS
OPTIONS.automatic.selected_values  = selected_values;

% Fusion of modalities in the selection: here we define OPTIONS.automatic.selected_samples
OPTIONS = be_fusion_of_samples(OPTIONS);

% We flag the boxes in the temporal interval of interest:
% Also remove edge effect.

t1 = max(OPTIONS.mandatory.DataTime(5), OPTIONS.optional.TimeSegment(1));
t2 = min(OPTIONS.mandatory.DataTime(end-5), OPTIONS.optional.TimeSegment(end));

tmi = OPTIONS.automatic.selected_samples(6,:)-2.^(OPTIONS.automatic.selected_samples(2,:)-1)/fs/2;
tma = OPTIONS.automatic.selected_samples(6,:)+2.^(OPTIONS.automatic.selected_samples(2,:)-1)/fs/2;
sl = ~((tma<=t1)|(tmi>=t2));
OPTIONS.automatic.selected_samples = [OPTIONS.automatic.selected_samples ; sl];
for ii = 1 : length(OPTIONS.mandatory.DataTypes)
    tmi = OPTIONS.automatic.Modality(ii).selected_jk(6,:)-2.^(OPTIONS.automatic.Modality(ii).selected_jk(2,:)-1)/fs/2;
    tma = OPTIONS.automatic.Modality(ii).selected_jk(6,:)+2.^(OPTIONS.automatic.Modality(ii).selected_jk(2,:)-1)/fs/2;
    sl = ~((tma<t1)|(tmi>t2));
    OPTIONS.automatic.selected_values{ii} = [OPTIONS.automatic.selected_values{ii} ; sl];
end

% we flag the boxes with the scales of interest:
if ~isempty(OPTIONS.wavelet.selected_scales) && logical(prod(OPTIONS.wavelet.selected_scales))
    sl = ismember(OPTIONS.automatic.selected_samples(2,:),OPTIONS.wavelet.selected_scales);
else
    if OPTIONS.optional.verbose
        fprintf('%s, No specific scales selected\n', OPTIONS.mandatory.pipeline);
    end
    OPTIONS.wavelet.selected_scales = sort(unique(OPTIONS.automatic.selected_samples(2,:)));
    sl = ones(1,size(OPTIONS.automatic.selected_samples,2));
end
OPTIONS.automatic.selected_samples = [OPTIONS.automatic.selected_samples ; sl];

% what do we keep finally ? coeff in the selected time window and selected
% scales:

sel = OPTIONS.automatic.selected_samples(8,:) .* OPTIONS.automatic.selected_samples(9,:);
OPTIONS.automatic.selected_samples = OPTIONS.automatic.selected_samples(:, sel == 1);
OPTIONS.automatic.selected_samples(8:end,:) = []; % (we can forget about the preselection, it is done)

% Keep only strongest t-f box
if OPTIONS.wavelet.single_box
    OPTIONS.automatic.selected_samples(:,2:end) = [];
end

if OPTIONS.optional.verbose
    fprintf('%s, wavelet selected boxes: you kept %d t-f boxes over a total of %d.\n', OPTIONS.mandatory.pipeline, size(OPTIONS.automatic.selected_samples,2), nSampleExtended);
end

end