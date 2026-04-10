function [OPTIONS, FLAG] = be_check_timedef(OPTIONS, isRF)

FLAG    =   0;

% Data length check
if strcmp(OPTIONS.mandatory.pipeline, 'cMEM') && strcmp(OPTIONS.clustering.clusters_type, 'static')
    
    % Min data duration : 25samples
    tmSMP   =   be_closest( OPTIONS.optional.TimeSegment([1 end]), OPTIONS.mandatory.DataTime );
    nSMP    =   diff( tmSMP ) + 1;
    minW    =   OPTIONS.optional.MSP_min_window;
    if nSMP < minW
        % try to expand the window
        neededSMP   =   ceil( (minW - nSMP)/2 );
        
        % available samples : left
        nSMPleft    =   tmSMP(1) - 1;
        
        % available samples : right
        nSMPright   =   numel(OPTIONS.mandatory.DataTime) - tmSMP(end);
        
        if any([nSMPleft nSMPright]<neededSMP)
            FLAG = 1;
            % can't expand the window
            fprintf('\nBEst error:\tdata is too short for stable clustering\n\t\tmust be at least %i samples long\n\n', minW);
        else
            OPTIONS.optional.TimeSegment    =   OPTIONS.mandatory.DataTime(tmSMP(1)-neededSMP : ...
                 tmSMP(end) + neededSMP);
            
            % expand the window
            fprintf('\nBEst warning:\tdata window was too short for stable clustering\n\t\texpanded so it contains %i samples\n', minW);
        end
        
    end
    
end


end
