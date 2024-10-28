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

    
    % apply the fusion of modalities
    OBJ_FUS = be_fusion_of_modalities(obj, OPTIONS, 0);
    
    if OPTIONS.model.depth_weigth_MNE > 0 || any(strcmp( OPTIONS.mandatory.DataTypes,'NIRS'))    
        J   =   be_jmne_lcurve(OBJ_FUS.G, OBJ_FUS.data, OPTIONS, struct('hfig',obj.hfig, 'hfigtab',obj.hfigtab)); 
    else
        J   =   be_jmne(OBJ_FUS.G,OBJ_FUS.data, OPTIONS);
    end
    
    MNEAmp =  max(max(abs(J))); %Same for both modalities
    for ii  =   1 : numel(OPTIONS.mandatory.DataTypes)
        OPTIONS.automatic.Modality(ii).Jmne = J / MNEAmp;
        OPTIONS.automatic.Modality(ii).MNEAmp = MNEAmp;
    end
    
end
