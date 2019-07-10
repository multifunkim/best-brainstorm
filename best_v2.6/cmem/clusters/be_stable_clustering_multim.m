function [SCR, CLS, OPTIONS] = be_stable_clustering_multim(obj, OPTIONS)
% BE_STABLE_CLUSTERING_MULTIM clusterizes the sources producing
% a spatial clustering stationary in time, while providing
% spatio-temporal evolution of MSP scores.
%
% This method is for data-driven spatio-temporal clustering
% has been described and validated in
% Chowdhury R.A., Lina J.M., Kobayashi E. and Grova C.
% MEG Source Localization of spatially extended generators of epileptic activity:
% Comparing Entropic and Hierarchical Bayesian Approaches.
% PLoS ONE 2013: 8(2):e55969
%
% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% INPUTS: 
%     - obj        : MEM obj structure
%     - OPTIONS    : Structure of parameters (described in be_main.m)
%        -automatic.Modality    : Structure containing the data and gain matrix for each modality
%          |- data              : Data matrix to process (channels x time samples)
%          |- gain_struct       : Structure returned by be_main_leadfields to give the normalized lead field.
%        -clustering            : Structure containing parcellization parameters                       
%          |- neighborhood_order: (Set to default 4) Nb. of neighbors used to clusterize 
%                                 cortical surface.
%        -optional              : Structure for setting optional parameters
%          |- cortex_vertices   : List of vertices in the cortical mesh.
%        -VertConn              : Neighborhood matrix 
%
% OUTPUTS:
%     - Results : Structure
%          |- OPTIONS       : Keep track of parameters
%          |- CLS           : Classification matrix. Contains labels
%          |                  ranging from 0 to number of parcels (1 column
%          |                  by time sample) for each sources.
%          |- SCR           : MSP scores matrix (same dimensions a CLS).
%
%
%% ==============================================
% Copyright (C) 2011 - MultiFunkIm &  LATIS Team
%
%  Authors: MultiFunkIm team, LATIS team, 2011
%  
%% ==============================================
% License
%
% BEst is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    BEst is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with BEst. If not, see <http://www.gnu.org/licenses/>.
% -------------------------------------------------------------------------

% Specific options
SVD_threshold = 0.95;

% Needed Data
OPTIONS.clustering.MSP_window = 1;
% test the field ModalityIndex in obj
if ~isfield(obj,'ModalityIndex')
    obj.ModalityIndex = 1;
end
M = OPTIONS.automatic.Modality(obj.ModalityIndex).data; % Make sure obj.ModalityIndex is correctly initialized
Gstruct = OPTIONS.automatic.Modality(obj.ModalityIndex).gain_struct; 
Cluster_Scale =  OPTIONS.clustering.neighborhood_order;
VertConn = obj.VertConn;
myVertices = OPTIONS.optional.cortex_vertices;


% ==== clustering technique
SCR = [];
CLS = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1- SVD of the DATA MATRIX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[U,S,V] = svd(M,0);
s = diag(S);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2- Threshold to identify the signal subspace (min 3 or 95% inertia)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

s = diag(S);
for i = 1:length(s)
    inertia(i) = sum(s(1:i).^2)./(sum(s.^2));
end
% cumsum
% q = max(3,min(find(inertia>=SVD_threshold)));
q = find(inertia>=SVD_threshold,1);
% ask for standard display with verbose
if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: dimension of the signal subspace %d, for inertia > %3.2f\n', OPTIONS.mandatory.pipeline,q,SVD_threshold);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3- MSP applied on each principal component of the signal subspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SPATIO_TEMPORAL EXTENSION of MSP scores in Signal Subspace (Refer to APPENDIX S1 in Chowdhury et al. 2013 Plos One
A = [];

nb_total_source = size(VertConn,1);
nb_time = size(M,2);
APM_tot = zeros(nb_total_source, nb_time);

for i = 1:q
    [APM, OPTIONS] = be_msp( U(:,i), Gstruct, OPTIONS);
%      [APM,I, ValP, VectP, OrtoP]  = doMSP(Gstruct.Gn,U(:,i),[],[],0);
    A = [A,APM];
    
    scale_prob = max(max(abs(V(:,1:q))));
    
    % SPATIO_TEMPORAL VERSION of MSP scores in Signal Subspace
    APM_tot = APM_tot + APM * abs(V(:,i)/scale_prob)';
end

APM_tot = APM_tot/max(max(APM_tot));


SCR = APM_tot;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4- Complete the MSP on the noise subspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Mnoise = U(:,q+1:end)*S(q+1:end,q+1:end)*V(:,q+1:end)';
[APM, OPTIONS] = be_msp( Mnoise, Gstruct, OPTIONS);

% A contains sequentially the MSP score associated to each principal
% component and then of the noise subspace
A = [A,APM];

% comp_label identifies for each source what is the component it is
% contributing more
[y,comp_label] = max(A,[],2);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5- Selection of active sources using a MSPthreshold estimated from the
% noise subspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

active_thresh = mean(APM); % possibility to use a FDR threshold here
out = find(y<=active_thresh);
comp_label(out) = 0; % set at 0 the label of sources considered as inactive because of low MSP score


var = setdiff(unique(comp_label),0);
comp_label(out) = max(var) +1; % set the inactive sources to the label NbComp + 1
NbComp = max(var);

si = sum(VertConn,2); % Number of 1st order neighbours associated to each vertex

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6- Spatial smoothing of the label map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DensityThresh = 0;


comp_label_NEW = corrET(comp_label,VertConn,NbComp,DensityThresh,OPTIONS);

out = find(comp_label_NEW==NbComp+1);

comp_label_NEW(out) = 0;

if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: spatial smoothing of every component done\n',OPTIONS.mandatory.pipeline);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 7- Construction of the CPM map in order to avoid sources associated to
% two component of signals to be associated in the same cluster
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
etval = setdiff(unique(comp_label_NEW),0);

NOISE = max(etval);
CPM = zeros( length(comp_label_NEW),length(comp_label_NEW));
for i = 1:length(comp_label_NEW)
    for j = 1:length(comp_label_NEW)
        if comp_label_NEW(i) == comp_label_NEW(j)
            if (comp_label_NEW(i) ~= NOISE)
                % the 2 sources have the same label different from NOISE,
                % they can belong to the same cluster
                CPM(i,j) = 1;
            else
                % the 2 sources are associated to the NOISE component
                CPM(i,j) = 0.5;
            end
        else
            % Two distinct labels
            if (comp_label_NEW(i) == NOISE)
                CPM(i,j) = 0.5; % we provide the possible to extent towards the NOISE component
            elseif (comp_label_NEW(j) == NOISE)
                CPM(i,j) = 0.5; % we provide the possible to extent towards the NOISE component
            else
                CPM(i,j) = 0 ; % the two sources are associated with two different components of interest
                % they cannot be fused in the same cluster
            end
        end
        
    end % for j
end % for i

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 8- STABLE CLUSTERING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


scale_k = Cluster_Scale;


ClusteredSource = [];
Seeds = cell(0);

for i = etval
    % Clustering of each signal component
    if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: clustering of component %d\n',OPTIONS.mandatory.pipeline,i);
    end
    AlreadyClustered = find(comp_label_NEW~=i);
    
    Seeds{i} = be_find_nuclei(A(:,i),myVertices, VertConn,AlreadyClustered,scale_k,OPTIONS);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: seed of component %d (ok)\n',OPTIONS.mandatory.pipeline,i);
    end
end



SeedsTot = [];
for i = etval
    SeedsTot = unique([SeedsTot Seeds{i}]);
end



clusters{scale_k} = be_msp_constrained_cluster(SeedsTot,CPM,VertConn,OPTIONS);

OPTIONS.optional.clustering = clusters{scale_k};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


out = find(comp_label_NEW==0);

if isempty(out) == 0
    clusters{scale_k, end+1} = out;
end

myCLS = zeros(size(myVertices,1),1);
CLS = zeros(size(myVertices,1),size(M,2));
mycluster = clusters{scale_k};
for ind = 1:length(mycluster)
    myCLS(mycluster{ind}) = ind;
end

for t=1:size(M,2)
    CLS(:,t) =  myCLS;
end


end




% return



%-----------------------------------------------------------
%----------- SUBFUNCTIONS ----------------------------------
%-----------------------------------------------------------



function [myLabelCorr] = corrET(myLabel,VertConn,NbComp,thresh,OPTIONS)
% Iterative local smoothing of a label map

stop = 0;
tmp = myLabel;
sout = [];


while stop == 0
    
    
    [out,Acor] = SpatC(tmp,VertConn,NbComp,thresh);
    
    
    
    if isempty(out) == 1                    %  stable point(in = out)
        if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: stable smoothing reached\n',OPTIONS.mandatory.pipeline);
        end
        stop = 1;
    elseif ismember(NbComp+1,unique(Acor)) == 0  % no more inactive sources
        if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: complete parcelling (ok)\n',OPTIONS.mandatory.pipeline);
        end
        stop = 1;
    else
        tmp = Acor;
        a = length(out);
        sout = [sout,a];
    end
    
    if length(sout) > 20
        if isequal(unique(sout(end-20:end)),sout(end)) == 1
        if OPTIONS.optional.verbose
        fprintf('%s, stable clustering: equilibrium reached, exchange of boundary points\n',OPTIONS.mandatory.pipeline);
        end
            stop = 1;
        else
            a = isequal(unique(sout(end-20:2:end)),sout(end-20));
            b = isequal(unique(sout(end-19:2:end)),sout(end-19));
            if a*b == 1             % cyce-frontiere de frequence 1/2
            if OPTIONS.optional.verbose
            fprintf('%s, stable clustering: stable smoothing reached\n',OPTIONS.mandatory.pipeline);
            end
                stop = 1;
            end
        end
    end
    
    
    
end

myLabelCorr = Acor ;

end



function [out,myLabelCorr] = SpatC(myLabel,VertConn,NbComp,s)
% Iterative local smoothing of a label map

for i = 1:length(myLabel)
    
    neighbours =  find(VertConn(i,:) == 1);
    
    dv = myLabel(neighbours);
    
    if s == -1
        thresh = max(2,length(neighbours)./2.5);
    else
        thresh = s;
    end
    
    udv = unique(dv);
    
    if length(udv) == 1
        % All neighbours are associated with the same label
        if udv == NbComp+1
            %Noise Label : nothing change
            avgi(i) = myLabel(i);
        else
            % Smooth Label since all the neighbour have the same label
            avgi(i) = udv;
        end
        
    else
        % Local spatial smoothing  of the labels
        [n,x] = hist(dv,udv);
        [f,g] = sort(n);
        
        if x(g(end)) == NbComp+1
            if n(g(end-1)) >= thresh
                avgi(i) = x(g(end-1));
            elseif n(g(end)) >= thresh
                avgi(i) = NbComp+1;
            else
                avgi(i) = myLabel(i);
            end
        else
            if n(g(end)) >= thresh
                avgi(i) = x(g(end));
            else
                avgi(i) = myLabel(i);
            end
        end
    end
    
end

myLabelCorr = avgi;

out = find(avgi(:)-myLabel(:) ~= 0);

end

