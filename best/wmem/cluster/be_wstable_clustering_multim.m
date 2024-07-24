function [CLS, SCR, OPTIONS] = be_wstable_clustering_multim(obj, OPTIONS)
% be_wstable_clustering_multim clusterizes the sources along the data 
% time window in a wavelet representation. Only tf-boxes with global energy with
% more than 0.1% of the variance (at each scale) is kept in the model. 
% This is using stable clustering
% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% INPUTS:
%     - WM      : Data matrix (wavelet rep.) to be reconstructed using MEM
%     - Gstruct : Structure returned by normalize_gain. See normalize_gain
%                 for more info.
%     - Nm      : Neighborhood matrix
%     - OPTIONS : Structure of parameters (described in be_memsolver_multiM.m)
%
% OUTPUTS:
%     - Results : Structure
%          |- OPTIONS       : Keep track of parameters
%          |- CLS           : Classification matrix. Contains labels
%          |                  ranging from 0 to number of parcels (1 column
%          |                  by time sample) for each sources.
%          |- SCR           : MSP scores matrix (same dimensions a CLS).
%
%

    % Initialize the MSP+clustering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    OPautomatic = OPTIONS.automatic;                                        %
    OPoptional  = OPTIONS.optional;                                         %
    nbb = size(OPautomatic.selected_samples,2);                             %
    nbS = size(OPautomatic.Modality(1).gain,2);                             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Stable clustering approach:
    if OPTIONS.optional.verbose
        fprintf('%s, stable clustering ...', OPTIONS.mandatory.pipeline);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Mod_in_box  = zeros(1,nbb); % To take into account the multi modality)%
    initTHR = OPTIONS.clustering.MSP_scores_threshold;                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    combinedSCR = zeros(nbS, 1);
    th = [1 1];

    % NO loop over the modalities HERE (only one modality)
    for jj = 1: numel(OPTIONS.mandatory.DataTypes)
        
        % List of TF-boxes of interest:
        BOX = OPautomatic.selected_samples(1,:); % box of interest
        % we compute Wavelet MSP over the full set of wavelet coeff:
        [scores, OPTIONS] = be_msp(obj.data{jj}(:,BOX), ...
                            OPautomatic.Modality(jj).gain_struct, ...
                            OPTIONS);
    
        if isempty(OPoptional.clustering.clusters)
	    % MSP scores threshold
            if strcmp(OPTIONS.clustering.MSP_scores_threshold, 'fdr')
                [th(jj), OPTIONS] = be_msp_fdr(scores, ...
                                  OPautomatic.Modality(jj).paramH0, OPTIONS);
            elseif isnumeric(OPTIONS.clustering.MSP_scores_threshold)
                th(jj) = OPTIONS.clustering.MSP_scores_threshold;
            end
         end
         combinedSCR = combinedSCR + scores - combinedSCR.*scores;
         Mod_in_box(1,:) = Mod_in_box(1,:)+jj;
    end
    % An identical score and threshold for all boxes
    % An identical parceling for all TF boxes:
    SCR = repmat(combinedSCR,1,nbb);
    THR = repmat(min(th),1,nbb);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(OPoptional.clustering.clusters)
        % we cluster the sources from the data
        OPTIONS.automatic.Mod_in_boxes = [Mod_in_box ; THR];
        OPTIONS.clustering.MSP_scores_threshold = THR(1,1);
        [OPTIONS, temp] = be_create_clusters(obj.VertConn, combinedSCR,OPTIONS );
        OPTIONS.clustering.MSP_scores_threshold = initTHR; % to restore the fdr option
        % the cluster config of the sources
        CLS = repmat(temp,1,nbb);
    else
        CLS = [];
    end

    % Stable clustering approach:
    if OPTIONS.optional.verbose
        fprintf('Done. \n');
    end
end
 