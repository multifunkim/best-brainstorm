function VertConn = be_vertex_connectivity(HeadModel)
% be_vertex_connectivity. 
% Extract the vertex connectivity matrix from HeadModel
% | Either HeadModel.VertConn or HeadModel.vertex_connectivity
% | If neither field are present, recreate it from HeadModel.Vertice and HeadModel.Faces

    if isfield(HeadModel, 'VertConn') && ~isempty(HeadModel.VertConn)
        VertConn = HeadModel.VertConn;    
    elseif isfield(HeadModel, 'vertex_connectivity') && ~isempty(HeadModel.vertex_connectivity)
        VertConn = HeadModel.vertex_connectivity; 
    elseif isfield(HeadModel, 'Vertices') && isfield(HeadModel, 'Faces')
        VertConn = be_get_neighbor_matrix( size(HeadModel.Vertices,1), HeadModel.Faces);
    else
        error('MEM >> No vertex connectivity matrix available.');
    end
    
end