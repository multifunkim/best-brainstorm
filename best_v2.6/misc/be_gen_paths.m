function be_gen_paths


Cpath   =   which(mfilename);

for ii  =   1 : 3
    Cpath   =   bst_fileparts(Cpath);
end

warning('OFF')
addpath( genpath(Cpath) );
        
        
        
return