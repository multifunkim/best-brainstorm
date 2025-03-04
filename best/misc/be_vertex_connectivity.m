function [OPTIONS, VertConn] = be_vertex_connectivity(HeadModel, OPTIONS)

    if isfield(HeadModel, 'VertConn')
        VertConn = HeadModel.VertConn;        
    elseif isfield(HeadModel, 'vertex_connectivity')
        VertConn = HeadModel.vertex_connectivity;   
    elseif ~OPTIONS.automatic.stand_alone 
        load( be_fullfile(OPTIONS.automatic.iProtocol.STUDIES, OPTIONS.optional.DataFile), 'Time')
        OPTIONS.mandatory.DataTime = Time;
        
        % Get study infos
        protoc      =	bst_get('ProtocolInfo');
        studID      =   be_get_id(OPTIONS);
        
        % Get subject headfile
        if ~isempty(HeadModel.SurfaceFile) && exist(be_fullfile(protoc.SUBJECTS,HeadModel.SurfaceFile), 'file')
            VCfile      =   be_fullfile(protoc.SUBJECTS,HeadModel.SurfaceFile); 
            load(VCfile, 'VertConn', 'Vertices', 'Faces');
        else
            stdINF      = bst_get('Study', studID);
            [dim, subID]= bst_get('Subject', stdINF.BrainStormSubject);
            cxfile      = bst_get('SurfaceFileByType', subID, 'Cortex');
            VCfile      = be_fullfile(protoc.SUBJECTS, cxfile.FileName);
            load( VCfile, 'VertConn', 'Vertices', 'Faces');
        end
            
        % If no VertConn
        if ~exist( 'VertConn', 'var' )
            VertConn = be.clusters.get_neighbor_matrix(Vertices, Faces.Faces);
            clear Faces 
        end    
        
        % Initialize vertices for cMEM
        if strcmp(OPTIONS.mandatory.pipeline, 'cMEM') && exist('Vertices', 'var')
            OPTIONS.optional.cortex_vertices    =   Vertices;
        end
        
    else
        error('>>> MEM error : insufficient information in head model (missing vertex connectivity)'); 
    end
end
