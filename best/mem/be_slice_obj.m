function [OPTIONS, obj_slice, obj_const] = be_slice_obj(Data, obj, OPTIONS)

    nbSmp               = size(Data,2); 
    obj_slice(nbSmp)    = struct();

    for i = 1:nbSmp

        obj_slice(i).clusters           = obj.CLS(:,i);
        obj_slice(i).active_probability = obj.ALPHA(:,i);

        obj_slice(i).data   = Data(:,i);
        obj_slice(i).time   = obj.time(:,i);
        obj_slice(i).scale  = obj.scale(:,i);

        obj_slice(i).Jmne   = OPTIONS.automatic.Modality(1).Jmne(:,i) ;
        obj_slice(i).Jmne   = obj_slice(i).Jmne ./ max(abs(obj_slice(i).Jmne));

        % check if there's a noise cov for each scale
        if (size(obj.noise_var,3) > 1) && OPTIONS.optional.baseline_shuffle ~= 1
            if OPTIONS.optional.verbose
                fprintf('%s, Noise variance at scale %i is selected\n',...
                    OPTIONS.mandatory.pipeline,OPTIONS.automatic.selected_samples(2,ii));
            end
            obj_slice(i).noise_var = squeeze(obj.noise_var(:,:,OPTIONS.automatic.selected_samples(2,ii)) );
        
        elseif (size(obj.noise_var,3)>1) && OPTIONS.optional.baseline_shuffle == 1
            tol = OPTIONS.optional.baseline_shuffle_windows / 2; 
            idx_baseline = find(obj.time(i) > OPTIONS.automatic.Modality(1).BaselineTime(1,:) & ...
                                obj.time(i) <=  (OPTIONS.automatic.Modality(1).BaselineTime(end,:)+tol));
        
            if isempty(idx_baseline) && obj.time(i) > max(max(OPTIONS.automatic.Modality(1).BaselineTime))
                idx_baseline = size(OPTIONS.automatic.Modality(1).BaselineTime,2);
            elseif isempty(idx_baseline) && obj.time(i) < min(min(OPTIONS.automatic.Modality(1).BaselineTime))
                idx_baseline = 1;
            elseif length(idx_baseline) > 1
                idx_baseline = idx_baseline(2);
            end
    
            if OPTIONS.optional.verbose
                fprintf('%s, Noise variance from baseline %i is selected\n',...
                    OPTIONS.mandatory.pipeline, idx_baseline);
            end
            obj_slice(i).noise_var = squeeze(obj.noise_var(:,:, idx_baseline) );
        else
            obj_const.noise_var = obj.noise_var;
        end

    end

    obj_const.nb_sources    = obj.nb_sources;
    obj_const.nb_channels   = obj.nb_channels;
    obj_const.nb_dipoles    = obj.nb_dipoles;


    obj_const.Sigma_s  = obj.Sigma_s;
    obj_const.GreenM2  = obj.GreenM2;
    obj_const.gain     = obj.gain;

    OPTIONS.automatic   = rmfield(OPTIONS.automatic,'Modality');
    OPTIONS             = rmfield(OPTIONS,'mandatory');
    OPTIONS.optional.TimeSegment = [];
    OPTIONS.optional.Baseline    = [];

    MAX_ITER = 10000;  % The maximum number of itterations
    OPTIONS.solver.optimoptions =   optimoptions('fminunc','GradObj', 'on', ...
                                                'MaxIter', MAX_ITER, ...
                                                'MaxFunEvals', MAX_ITER, ...
                                                'algorithm', 'trust-region',...
                                                'Display', 'off' );
end
