function [D, dD] = be_free_energy(lambda, M, noise_var, ...
    clusters, nb_clusters, varargin)
%CALCULATE_FREE_ENERGY gives the free energy of a system
%   [D, dD] = CALCULATE_FREE_ENERGY(LAMBDA, M, NOISE_VAR, CLUSTERS,
%   NB_CLUSTERS)
%   calculates the free energy of the system for a given LAMBDA and 
%   returns it in D. The function also returns the derivative of D with 
%   respect to LAMBDA in dD.  This method should not be called by itself.
%
%   The method uses the methodoly described in :
%   Amblard, C., Lapalme, E., Lina, J. 2004. Biomagnetic Source Detection
%       by Maximyum Entropy and Graphical  Models, IEEE Transactions on 
%       Biomedical Engineering, vol. 51, no 3, p. 427-442.
%
%   The formulas are :
%       D(lambda) = lambda' * M - 
%                   (1/2)* noise_var * lambda' * lambda - 
%                   sum(F* * (G' * lambda))
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

%warning off
if ~isempty(varargin)
    omega=varargin{1};
else
    omega=[];
end

% variable change to reflect the notation in the reference paper

% SOLVING THE EQUATIONS
% Ref. eq (19) from Amblard's paper. Second term is noise term assuming
% Normal law distribution.
lambda_trans = lambda';      
D = lambda_trans * M - (1/2) * lambda_trans * noise_var * lambda;

%Same for derivative wrt lambda
dD = M - noise_var * lambda;

% Third term of the equation and the derivative is substracted from
% D(lambda) and dD(lambda) respeectively. The sum is calculated over each
% cluster

isUsingActiveMean = ~isempty(clusters(1).active_mean);

for ii = 1:nb_clusters
    
    active_probability = clusters(ii).active_probability;

    if ~isempty(omega)
        xi = clusters(ii).G' * lambda;
    end
         
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Estimating dF*(xi) (before F*(xi) to optimize the computing time
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dF was split into dF1a and dF1b for optimization purposes only.
    
    % Sigma (active_var) is a symetric matrix, the transpose is not necessary
    % dF1a = G * active_var * xi =  G * active_var * G' * lambda. 
    % G *active_var * G'  is precomputed and stored in G_active_var_Gt
    dF1a = clusters(ii).G_active_var_Gt * lambda; 

    if isUsingActiveMean
        active_mean        = clusters(ii).active_mean;

        dF1b = clusters(ii).G * active_mean;
        dF1 = dF1a + dF1b;
    else
        dF1 = dF1a;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Estimating F*(xi)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % F0 is set to a dirac by default (omega=0).
    if isempty(omega)
        F0=0;
    else
        F0 = 1/2 * xi' * omega * xi;
    end
    
    
    % F1 is split into F1a and F1b and added on a separate line for
    % optimization purposes only.
    F1a = 1/2 * lambda_trans * dF1a;
    
    if isUsingActiveMean
        F1b = lambda_trans * dF1b;
        F1 = F1a + F1b;
    else
        F1 = F1a;
    end

    % This equation can be unstable
    % F = ln((1-alpha(ii)) * exp(F0) + alpha(ii) * exp(F1));
    
    %TO CHECK: not sure how it's more stable...
    % Reorganizing the equations for better results yields:
    % F*(xi)  = F1 + ln( (1-alpha) exp(F0 - F1) + alpha) if F1 > F0
    % F*(xi)  = F0 + ln( (1-alpha) + alpha * exp(F1-F0) ) if F1 < F0

    if isempty(omega) % we know that f_max = F1 and F0 = 0
        F_max = F1;

        % free_energy = [exp(-F_max)  ; 1 ];  we dont need to compute as we
        % only need free_energy(2) = 1

        coeffs_free_energy = (1-active_probability) * exp(-F_max)  +  active_probability;

        F = F_max + log(coeffs_free_energy);
    else

        F_max = max(F0,F1);
        free_energy = exp([F0;F1] - F_max);
        coeffs_free_energy = [1-active_probability,  active_probability] *  free_energy;
        F = F_max + log(coeffs_free_energy);
    end
    
    % ERROR when coeffs_free_energy == 0
    if isinf(F)

        F = F_max;
        dF = 0;

    else
        if isempty(omega)
            % dF0 = zeros(size(dF1));   free_energy(2)  == 1
            dF  = dF1 *  active_probability / coeffs_free_energy;
        else
            dF0 = clusters(ii).G * omega * xi;
            dF = [ (1 - active_probability)*dF0,  active_probability*dF1] * free_energy ./ coeffs_free_energy;
        end
    
    end

    % Substracting from D(lambda)
    D = D - F;  % Eq. (19) from paper

    % Substracting from dD(lambda)
    dD = dD - dF;
end

% The outcome of the equations produces a strictly convex function
% (with a maximum).
D = -D;
dD = -dD;

end
