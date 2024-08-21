function [J,varargout] = be_jmne_lcurve(G,M,OPTIONS, sfig)
% Compute the minimum norm estimate using the regularized pseudo-inverse formula
% the regularization parameter is estiamted using l-curve. This approach is
% equivalent to the MAP estimator in be_jmne_lcurve_MAP
%   INPUTS:
%       -   G       : matrice des lead-fields (donnee par le probleme direct)
%       -   M       : vecteur colonne contenant les donnees sur les capteurs
%
%   OUTPUTS:
%       -   J       : regularized pseudo-inverse estimator
%       -   varargout{1} : regularization parameter based on l-curve
%% ==============================================
% Copyright (C) 2024 - Edouard Delaire
%
%  Authors: Edouard Delaire, 2024
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

    if nargin < 4 
        sfig = struct('hfig', [], 'hfigtab', []);
    end
    
    % selection of the data:
    if ~isempty(OPTIONS.automatic.selected_samples)   
        selected_samples = OPTIONS.automatic.selected_samples(1,:);
        M = M(:,selected_samples);
    end
    
    
    fprintf('%s, solving MNE by L-curve ...', OPTIONS.mandatory.pipeline);
    
    % Compute covariance matrices
    if 1 || isempty(OPTIONS.automatic.Modality(1).covariance)
        Sigma_d    =   eye(size(M,1));  
    else
        Sigma_d    =   OPTIONS.automatic.Modality(1).covariance;
    end


    p       = OPTIONS.model.depth_weigth_MNE;
    if isempty(OPTIONS.automatic.Modality(1).covariance)
        Sigma_s = diag(power(diag(G'*inv(Sigma_d)*G),-p)); 
    else
        Sigma_s = diag(power(diag(G'*G),-p)); 
    end
    

    % Pre-compute matrix
    GSG = G * Sigma_s * G';
    SG  = Sigma_s * G';

    % Note W*S*G: W = Sigma_s^-0.5 so W*Sigma_s = Sigma_s^0.5
    wSG = sqrt(Sigma_s) * G';

    % Parameter for l-curve
    param1  = [0.1:0.1:1 1:5:100 100:100:1000]; 

    % Scale alpha using trace(G*G')./trace(W'*W)  
    scale   = trace(G*G')./ trace(inv(Sigma_s));       
    alpha   = param1.*scale;


    Fit     = zeros(1,length(alpha));
    Prior   = zeros(1,length(alpha));
    if ~OPTIONS.automatic.stand_alone
        bst_progress('start', 'wMNE, solving MNE by L-curve ... ' , 'Solving MNE by L-curve ... ', 1, length(param1));
    end
    for iAlpha = 1:length(alpha)
        
        inv_matrix = inv( GSG  + alpha(iAlpha) * Sigma_d );
        
        residual_kernal = eye(size(M,1)) - GSG * inv_matrix;
        wKernel = wSG*inv_matrix;

        Fit(iAlpha)     = normest(residual_kernal*M);  % Define Fit as a function of alpha
        Prior(iAlpha)   = normest(wKernel*M);      % Define Prior as a function of alpha
        if ~OPTIONS.automatic.stand_alone
            bst_progress('inc', 1); 
        end
    end

    % Fid alpha optimal based on l-curve
    [~,Index] = min(Fit/max(Fit)+Prior/max(Prior)); 
    
    Kermel = SG * inv( GSG  + alpha(Index) * Sigma_d );
    J = Kermel*M; 

    if nargout > 1
        varargout{1} = alpha(Index);
    end

    if ~OPTIONS.automatic.stand_alone
        bst_progress('stop');
    end
    fprintf('done. \n');
    
    if OPTIONS.optional.display
        if isempty(sfig.hfig)
            sfig.hfig =  figure();
            sfig.hfigtab = uitabgroup;
        end
    
        onglet = uitab(sfig.hfigtab,'title','L-curve');
    
        hpc = uipanel('Parent', onglet, ...
                  'Units', 'Normalized', ...
                  'Position', [0.01 0.01 0.98 0.98], ...
                  'FontWeight','demi');
        set(hpc,'Title',' L-curve ','FontSize',8);
    
        ax = axes('parent',hpc, ...
                  'outerPosition',[0.01 0.01 0.98 0.98]);
    
        hold on; 
        plot(ax, Prior, Fit,'b.');
        plot(ax, Prior(Index), Fit(Index),'ro');
        hold off;
        xlabel('Norm |WJ|');
        ylabel('Residual |M-GJ|');
    end

end