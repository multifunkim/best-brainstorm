function [OPTIONS, VertConn] = be_vertex_connectivity(HeadModel, OPTIONS)
% be_vertex_connectivity. Extract the vertex connectivity matrix from
% HeadModel (either HeadModel.VertConn or HeadModel.vertex_connectivity). 
% If neither field are present, try to load the vertex connectivity matrix
% from Brainstorm. 


    % Option 1.  VertConn is provided in the headmodel 

    if isfield(HeadModel, 'VertConn') && ~isempty(HeadModel.VertConn)
        VertConn = HeadModel.VertConn;    
        return; 
    elseif isfield(HeadModel, 'vertex_connectivity') && ~isempty(HeadModel.vertex_connectivity)
        VertConn = HeadModel.vertex_connectivity; 
        return;
    elseif OPTIONS.automatic.stand_alone  
        error('MEM >> No vertex connectivity matrix available.');
    end

    % Option 2.  Load VertConn from Brainstorm
    
    % Get study infos
    protoc      =	bst_get('ProtocolInfo');
    studID      =   be_get_id(OPTIONS);
    
    % Get subject headfile
    if ~isempty(HeadModel.SurfaceFile) && exist(be_fullfile(protoc.SUBJECTS,HeadModel.SurfaceFile), 'file')
        VCfile      =   be_fullfile(protoc.SUBJECTS,HeadModel.SurfaceFile); 

        sCortex = load(VCfile, 'VertConn', 'Vertices', 'Faces');
    else

        stdINF      = bst_get('Study', studID);
        [dim, subID]= bst_get('Subject', stdINF.BrainStormSubject);
        cxfile      = bst_get('SurfaceFileByType', subID, 'Cortex');
        VCfile      = be_fullfile(protoc.SUBJECTS, cxfile.FileName);

        sCortex = load( VCfile, 'VertConn', 'Vertices', 'Faces');
    end
        
    if isfield(sCortex, 'VertConn') && ~isempty(sCortex.VertConn)
        VertConn = sCortex.VertConn;    
    elseif isfield(sCortex, 'Vertices') && isfield(sCortex, 'Faces')
        VertConn = be_get_neighbor_matrix( size(sCortex.Vertices,1), sCortex.Faces);
    else
        error('MEM >> No vertex connectivity matrix available.\n');
    end    
    
end