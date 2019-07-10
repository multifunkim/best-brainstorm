function [AVG] = be_avgcell(ARRAY)
    
    AVG = sparse( size(ARRAY{1},1), size(ARRAY{1},2) );
    nAR = numel(ARRAY);
    for ii = 1 : nAR
        if size(ARRAY{1}) ~= size(ARRAY{ii})
            error('Cells contents have different dimensions')
        end            
        AVG = AVG + ARRAY{ii} / nAR;
        
    end
return