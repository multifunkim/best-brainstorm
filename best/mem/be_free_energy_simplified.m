function [D, dD, H] = be_free_energy_simplified(lambda, M, noise_var, G_active_var_Gt, clusters)
%CALCULATE_FREE_ENERGY gives the free energy of a system
%   [D, dD] = CALCULATE_FREE_ENERGY(LAMBDA, M, NOISE_VAR, CLUSTERS, NB_CLUSTERS)
%   calculates the free energy of the system for a given LAMBDA and 
%   returns it in D. The function also returns the derivative of D with 
%   respect to LAMBDA in dD.  This method should not be called by itself.
%   
%   Warning: This function assume that the active mean is 0, and inactive
%   parcels are dirac at 0. For more options, use be_free_energy. 
%   This limitation allows us to also compute the Hessian H. 
% 
%   The method uses the methodoly described in :
%   Amblard, C., Lapalme, E., Lina, J. 2004. Biomagnetic Source Detection
%       by Maximyum Entropy and Graphical  Models, IEEE Transactions on 
%       Biomedical Engineering, vol. 51, no 3, p. 427-442.
%
%   The formulas are :
%       D(lambda) = lambda' * M - 
%                   (1/2)* noise_var * lambda' * lambda - 
%                   sum(F*(G' * lambda))
%
%       F*(xi) = ln[(1- alpha) * exp(F0) + alpha * exp(F1)]
%           where F0 is the inactive state and
%                 F1 is the active state
%       F0(xi) = 1/2 * xi' * omega * xi
%       F1(xi) = 1/2 * xi' * sigma * xi + xi' * mu
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

    lambda_trans = lambda';      
    p            = [clusters.active_probability];
    
    % Estimate dF1 and F1 (separating the contribution  of the mean and
    % covariance for optimization purpose)
    dF1     = squeeze(be_pagemtimes(G_active_var_Gt,lambda));
    F1      =  1/2 * lambda_trans*dF1; 
    
    % Finally estimate dF and F
    coeffs_free_energy  = (1-p) .* exp(-F1)  +  p;
    s1   = p ./ coeffs_free_energy;
    
    F = F1 + log(coeffs_free_energy);
    dF  = s1 .* dF1;
    
    
    % The outcome of the equations produces a strictly convex function (with a maximum).
    D   = -(lambda_trans * M - sum(F) - (1/2) * lambda_trans * noise_var * lambda);
    
    % Compute the gradient
    if nargout >= 2
        dD  = -(               M - sum(dF,2)                     - noise_var * lambda);
    end
    
    % Compute the Hessian
    if nargout >= 3
        
        % Curvature term: sum_i s1_i * G*Sigma_i*G'               
        curvature_term = squeeze(pagemtimes(permute(G_active_var_Gt, [2, 3, 1]), s1'));

        % Rank-1 term: sum_i s1_i*(1-s1_i) * delta_i*delta_i'
        w_delta      = dF1 .* sqrt(s1 .* (1 - s1));
        rank1_term   = w_delta * w_delta'; 
        
        H = curvature_term + rank1_term + noise_var;
    end


end
