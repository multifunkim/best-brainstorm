function res = be_canUsefminunc()
    %be_canUsefminunc Determine if the user can use the matlab fminunc" function that requires a licence
        res = license('test', 'Optimization_Toolbox') && ...
              exist('fminunc', 'file');
    end
    
    