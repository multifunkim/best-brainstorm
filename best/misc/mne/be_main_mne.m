function [obj, OPTIONS] = be_main_mne(obj, OPTIONS)
% BE_MAIN_MEM sets the appropriate options for the MNE 
% accroding to the chosen MEM pipeline. Populate the fields
%   OPTIONS.automatic.Modality(ii).Jmne = J * ratioAmp;
%   OPTIONS.automatic.Modality(ii).ratioAmp = ratioAmp; with ratioAmp =  1 / max(max(abs(J))); 
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
%       -   OPTIONS
%       -   obj

%Local fusion of data and gain matrix to compute the
%regularisation parameter (J)
    
    % Load head model
    G = vertcat(OPTIONS.automatic.Modality.gain);

    % Load data
    if isfield(obj, 'data') % wavelet
        M = vertcat(obj.data{:});
    else % Time-series
        M = vertcat(OPTIONS.automatic.Modality.data);
    end
    
    if OPTIONS.model.depth_weigth_MNE > 0 || any(strcmp( OPTIONS.mandatory.DataTypes,'NIRS')) 
        
        J   =   be_jmne_lcurve(G,M,OPTIONS, struct('hfig',obj.hfig, 'hfigtab',obj.hfigtab)); 
    else
        J   =   be_jmne(G,M,OPTIONS);
    end
    
    MNEAmp =  max(max(abs(J))); %Same for both modalities
    for ii  =   1 : numel(OPTIONS.mandatory.DataTypes)
        OPTIONS.automatic.Modality(ii).Jmne = J / MNEAmp;
        OPTIONS.automatic.Modality(ii).MNEAmp = MNEAmp;
    end
    
end
