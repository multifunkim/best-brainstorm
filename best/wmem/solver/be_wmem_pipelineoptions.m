function DEF = be_wmem_pipelineoptions(DataTypes)
        
        if nargin < 1 || isempty(DataTypes)
            DataTypes = {'EEG'};
        end

        % clustering
        DEF.clustering.clusters_type        = 'static';
        if any(ismember( 'NIRS', DataTypes))
            DEF.clustering.neighborhood_order       = 6;                       
        else
            DEF.clustering.neighborhood_order       = 4;                       
        end

        DEF.clustering.MSP_window         	= 1;
        DEF.clustering.MSP_scores_threshold = 0;

        % model
        DEF.model.alpha_threshold       = 0;
        DEF.model.active_mean_method    = 2;

        if any(ismember( 'NIRS', DataTypes))
            DEF.model.alpha_method      = 7;
        else
            DEF.model.alpha_method      = 6;
        end


        if any(ismember( 'NIRS', DataTypes))
            DEF.model.depth_weigth_MNE          = 0.3;
            DEF.model.depth_weigth_MEM          = 0.3;
        else
            DEF.model.depth_weigth_MNE          = 0.5;
            DEF.model.depth_weigth_MEM          = 0.5;
        end
        
        % wavelet processing
        DEF.wavelet.type                = 'rdw';
        DEF.wavelet.vanish_moments      = 3;
        DEF.wavelet.order               = 10;
        DEF.wavelet.nb_levels           = 128;
        DEF.wavelet.shrinkage           = 0;
        DEF.wavelet.selected_scales     = 0;
        DEF.wavelet.verbose             = 0;
        DEF.wavelet.single_box          = 0;
        
        % automatic
        DEF.automatic.selected_samples  = [];
        DEF.automatic.selected_jk       = [];
        DEF.automatic.selected_values   = [];
        DEF.automatic.Mod_in_boxes      = [];
        DEF.automatic.scales            = [];
        
        % solver
        DEF.solver.spatial_smoothing    = 0.6;
        DEF.solver.Optim_method         = 'fminunc';
        DEF.solver.NoiseCov_method      = 6;
        DEF.solver.mne_use_noiseCov     = 0;

        % optional
        if any(ismember( 'NIRS', DataTypes))
            DEF.optional.normalization      = 'adaptive'; 
        else
            DEF.optional.normalization      = 'fixed'; 
        end
        
        DEF.optional.baseline_shuffle   = 0;
        DEF.optional.baseline_shuffle_windows = 1; % in seconds

return