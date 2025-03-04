function [MEMoptions] = be_load_baseline(MEMoptions)
%BE_LOAD_BASELINE Load baseline, if Baseline is a path to a baseline file.

    % Patch work [to be revisited]... Baseline no longer preloaded...
    if ~isempty(MEMoptions.optional.Baseline) && ischar(MEMoptions.optional.Baseline)
        MEMoptions.optional.BaselineTime = getfield(load(MEMoptions.optional.Baseline, 'Time'), 'Time');
        MEMoptions.optional.Baseline = getfield(load(MEMoptions.optional.Baseline, 'F'), 'F');
    end

    if ~isempty(MEMoptions.optional.BaselineChannels) && ischar(MEMoptions.optional.BaselineChannels)
        MEMoptions.optional.BaselineChannels = getfield(load(MEMoptions.optional.BaselineChannels, 'BaselineChannels'), 'BaselineChannels');
    end

end

