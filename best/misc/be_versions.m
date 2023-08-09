function version = be_versions()


path = fileparts(which('be_versions'));

id  = fopen(fullfile(path, '..','VERSION.txt'));
str = fread(id,'*char' )';
tmp = strsplit(str,'\n');

version = tmp{1};

end

