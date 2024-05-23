function tf = be_canUseParallelPool()
%BE_CANUSEPARALLELPOOL Determine if the user can use parallel computing

    if ~verLessThan('matlab','9.9') % Matlab 2020b or  newer
        tf = canUseParallelPool();
    else
        tf = ~((exist('matlabpool', 'file') ~= 2) && (exist('parpool', 'file') ~= 2));
    end
end

