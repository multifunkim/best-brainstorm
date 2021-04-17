function be_gen_paths
% This function should be revisited, not necessary anymore...
Cpath   =   which(mfilename);

idSep   =   strfind( Cpath, filesep );
Cpath(idSep(end):end) = [];

warning('OFF')
% should add [./brainentropy] instead of [./brainentropy/best/misc]
addpath( genpath(fileparts(fileparts(Cpath))) );        
                
return
