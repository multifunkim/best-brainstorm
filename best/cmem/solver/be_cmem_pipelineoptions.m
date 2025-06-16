function DEF = be_cmem_pipelineoptions(DataTypes)

        if nargin < 1 || isempty(DataTypes)
            DataTypes = {'EEG'};
        end

        % clustering
        DEF.clustering.clusters_type     	= 'static';
        DEF.clustering.neighborhood_order   = 4;                       
        DEF.clustering.MSP_window         	= 1;
        DEF.clustering.MSP_scores_threshold = 0.0;
        
        DEF.model.alpha_threshold          	= 0.0;
        DEF.model.active_mean_method      	= 2;
        DEF.model.alpha_method              = 3;

        if any(ismember( 'NIRS', DataTypes))
            DEF.model.depth_weigth_MNE          = 0.3;
            DEF.model.depth_weigth_MEM          = 0.3;
        else
            DEF.model.depth_weigth_MNE          = 0.5;
            DEF.model.depth_weigth_MEM          = 0.5;
        end


        % automatic 
        DEF.automatic.selected_samples       = [];
        
        % solver
        DEF.solver.NoiseCov_method           = 2;
        DEF.solver.mne_use_noiseCov          = 0;

        % optional
        DEF.optional.normalization           = 'adaptive'; 

end