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

    if numel(OPTIONS.mandatory.DataTypes)>1 
        M = [OPTIONS.automatic.Modality(1).data;OPTIONS.automatic.Modality(2).data];
        G = [OPTIONS.automatic.Modality(1).gain;OPTIONS.automatic.Modality(2).gain];
    else
        M   =   OPTIONS.automatic.Modality(1).data;
        G   =   OPTIONS.automatic.Modality(1).gain;
    end
    
    if OPTIONS.model.depth_weigth_MNE > 0 || any(strcmp( OPTIONS.mandatory.DataTypes,'NIRS')) 
        J   =   be_jmne_lcurve(G,M,OPTIONS); 
    else
        J   =   be_jmne(G,M,OPTIONS);
    end
    
    MNEAmp =  max(max(abs(J))); %Same for both modalities
    for ii  =   1 : numel(OPTIONS.mandatory.DataTypes)
        OPTIONS.automatic.Modality(ii).Jmne = J / MNEAmp;
        OPTIONS.automatic.Modality(ii).MNEAmp = MNEAmp;
    end
    
end
