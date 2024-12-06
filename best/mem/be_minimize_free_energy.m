function [lambda, entropy, iter] = be_minimize_free_energy(mem_struct)
%MINIMIZE_FREE_ENERGY returns the minimum of a function
%   [LAMBDA, ENTROPY, ITER] = MINIMIZE_FREE_ENERGY(MEM_STRUCT)
%   miminizes the function "calculate_free_energy" and returns the optimal
%   parameter in LAMBDA and the value in ENTROPY drop. It also returns the
%   number of iterations it took to minimize the function. MEM_STRUCT is a
%   structure with the initial parameters of the MEM created with the
%   function the function  MEMSTRUCT.  Please see the help of
%   this function for more information.
%
%   The method uses the methodoly described in :
%   Amblard, C., Lapalme, E., Lina, J. 2004. 'Biomagnetic Source Detection
%       by Maximum Entropy and Graphical  Models '. IEEE Transactions on
%       Biomedical Engineering, vol. 51, no 3, p. 427-442.
%
% ==============================================
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



% MINIMIZING THE FUNCTION

if license('test', 'Optimization_Toolbox') && ...
        strcmpi(mem_struct.optim_algo, 'fminunc') && ...
        exist('fminunc', 'file')

    % call the unconstrained minimization routine from MATLAB optimization
    %  toolbox, if available.

    [lambda, entropy, xxx, out]  = fminunc(...
        @be_free_energy , ...
        mem_struct.lambda, ...
        mem_struct.optimoptions, ...
        mem_struct.M, ...
        mem_struct.noise_var, ...
        mem_struct.G_active_var_Gt, ...
        mem_struct.clusters);
    iter = out.iterations;
    
else
    % call an alternate unconstrained minimization routine if Matlab
    %  optimization toolbox is not available. Uses Mark Schmidt's
    % implementation of Nocedal's Quasi Newton method with BFGS updates
    % See minFunc.m for additional options.
    if strcmpi(mem_struct.optim_algo, 'fminunc')
        disp(['BEst> No license found for the Optimization Toolbox or ', ...
            'missing the function ''fminunc''.'])
        disp('BEst> Using alternate optimization routine...')
    end
    
    options = [];
    options.MaxIter = MAX_ITER;
    options.MaxFunEvals = MAX_ITER;
    options.Display = 'off';
    if strcmpi(mem_struct.optim_algo, 'minfuncnm')
        options.useMex = 0;
    end
    
    [lambda, entropy, xxxx, out]  = minFunc(...
        @be_free_energy , ...
        mem_struct.lambda, ...
        mem_struct.optimoptions, ...
        mem_struct.M, ...
        mem_struct.noise_var, ...
        mem_struct.G_active_var_Gt, ...
        mem_struct.clusters);
    iter = out.iterations;
end
end
