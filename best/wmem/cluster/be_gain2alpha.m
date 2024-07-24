function [alpha, CLS, OPTIONS] = be_gain2alpha(obj, CLS, OPTIONS, varargin)
% BE_GAIN2ALPHA computes the initial probability of a parcel being active in 
%   the MEM model without using the MSP scores.
%
%   INPUTS:
%       -   SCR     : vector of MSP scores with dimension Nsources
%       -   CLS     : vector of parcel labels for each source (1xNsources)
%       -   OPTIONS : 
%               model.alpha_method  :   method of initialization of the active           
%                   initial parcel active probabilities. (6=% of the MNE energy in the parcel)
%
%               model.alpha_threshold:  threshold on the active probabilities. 
%                   All prob. < threshold are set to 0 (parcel not part of the 
%                   MEM solution
%
%   OUTPUTS:
%       - OPTIONS   : Keep track of parameters
%       -   ALPHA   : vector of probabilities (1xNparcels)
%       -   CLS     : cell array (1xNparcels). Each cell contains the indices of        
%                     the sources within that parcel
%
%% ==============================================
% Copyright (C) 2011 - LATIS Team
%
%  Authors: LATIS team, 2011
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

                                                        
alpha = zeros(size(CLS));
ALPHA_METHOD = OPTIONS.model.alpha_method;

BOX = OPTIONS.automatic.selected_samples(1,:); % box of interest

Mn = []; 
for iMod = 1:length(OPTIONS.automatic.Modality)  

    M = obj.data{iMod}(:,BOX);
    % Normalize the data matrix. Eliminate any resulting NaN.
    Mn = vertcat( Mn, bsxfun(@rdivide, M, sqrt(sum(M.^2, 1))));
end

Mn(isnan(Mn)) = 0;


% New alpha scores 
Gn = [];
for iMod = 1:length(OPTIONS.automatic.Modality)  
    Gn = vertcat(Gn, OPTIONS.automatic.Modality(iMod).gain_struct.Gn);
end

Op = Gn'*pinv(Gn*Gn');
weight_alpha = Op * Mn;


% Progress bar
hmem = [];
if numel(varargin)
    hmem    = varargin{1}(1);
    st      = varargin{1}(2);
    dr      = varargin{1}(3);
end

for jj=1:size(CLS,2)
    clusters = CLS(:,jj);
    nb_clusters = max(clusters);
    curr_cls = 1;
    for ii = 1:nb_clusters
        idCLS = clusters==ii;
        switch ALPHA_METHOD
                
            case 6  % Method 1 (alpha = % of MNE energy inside the parcel)
                WSjj = weight_alpha(:,jj).^2;
                WSjj_ii = WSjj(idCLS); 
                alpha(idCLS,jj) = sqrt((sum(WSjj_ii) / sum(WSjj)));
                
            otherwise
                error('Wrong ALPHA Method')
        end
        
        CLS(idCLS,jj) = curr_cls;
        curr_cls = curr_cls + 1;
        
        % update progress bar
         if hmem
             prg = round( (st + dr * (jj - 1 + ii/nb_clusters) / (size(CLS,2))) * 100 );
             waitbar(prg/100, hmem, {[OPTIONS.automatic.InverseMethod, 'Step 1/2 : Running cortex parcellization ... ' num2str(prg) ' % done']});
         end
    end
    
end

% REMOVING CLUSTERS WITH ALPHA < APLHA_THRESHOLD
 alpha(alpha > 0.8) = 1;
end
