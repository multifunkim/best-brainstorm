function [J,varargout] = be_solve_l_curve_mne(G,M,OPTIONS)
% BAYESEST2 solves the inverse problem by estimating the maximal posterior probability (MAP estimator).
%
%   INPUTS:
%       -   G       : matrice des lead-fields (donnee par le probleme direct)
%       -   M       : vecteur colonne contenant les donnees sur les capteurs
%       -   InvCovJ : inverse covariance matrix of the prior distribution
%       -   varargin{1} : param (alpha = param. trace(W*W')./trace(G*G')
%                   NB: sinon, alpha est evalue par la methode de la courbe en L
%
%   OUTPUTS:
%       -   J       : MAP estimator
%       -   varargout{1} : param
%       -   varargout{2} : pseudo-inverse of G
%% ==============================================   
% Copyright (C) 2011 - Christophe Grova
%
%  Authors: Christophe Grova, 2011
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
                                 
params = [1e-05 5e-05 1e-04 5e-04 1e-03 2.5e-03 5e-03 7.5e-03...
          1e-02 2.5e-02 5e-02 7.5e-02 1e-01 2.5e-01 5e-01 0.75 ...
          1.0 1.25 1.5 2 3 4 5 6 7 8 9 10 11 12 13 14 15 17.5 20 ...
          25 30 35 40 45 50 75 100 150 200 300 400 500 750 1000 ...
          1500 2000 3000 4000 5000 10000 15000 20000 30000];

n_sour = size(G,2);
n_capt = size(G,1);
% selection of the data for the L-curve:
sample = bst_closest(OPTIONS.optional.TimeSegment([1 end]), OPTIONS.mandatory.DataTime);
M = M(:,sample(1):sample(2));
TrW    = n_sour;

% we solve J = (W'W)^-1.G'.( G.(W'W)^-1.G' + alpha.Id )^-1.M
    GG = G*G';
    TrG   = trace(GG);
    ratio = TrG/TrW;

% L-curve
    
    longPARAM = length(params);
    mat_norm=[];
       
    for p=1:2:longPARAM;  % we keep half of the lambdas
        
        alpha = params(p)*ratio;
        % we solve J = (W'W)^-1.G'.( G.(W'W)^-1.G' + alpha.Id )^-1.M
        J = G'*( GG + alpha.*eye(n_capt))^-1*M;
        
        residual = M-G*J;
        residual = residual.^2;
        residual = sqrt(sum(sum(residual)));
        
        normJ = zeros(2,1);
        Wj = sqrt(sum(sum(J.^2))); % we take metric W = 1
        normJ(1,1) = Wj; % norme de J au carre
        normJ(2,1) = residual; % |M-GJ| au carre
        mat_norm = [mat_norm normJ];
        clear J residual alpha normJ Wj;
    end
    L_values = mat_norm(1,:)/max(mat_norm(1,:))+mat_norm(2,:)/max(mat_norm(2,:));
    [minimum,index] = min(L_values);
    X = mat_norm(1,min(index));
    pos = find(mat_norm(1,:) == X);
      
    if OPTIONS.optional.display
        fprintf('%s, Figure of the L-curve\n', OPTIONS.mandatory.pipeline);
        figure; plot(mat_norm(1,:),mat_norm(2,:),'r.')
        hold on, plot(mat_norm(1,pos),mat_norm(2,pos),'bo')
        ylabel('residual |M-GJ|')
        xlabel('Norm |WJ|')
        title('L curve');
    end
            
    param1 = params(pos);
    alpha = param1*ratio;

% on resout J = (W'W)^-1.G'.( G.(W'W)^-1.G' + alpha.Id )^-1.M
    invG = G'*( GG + alpha.*eye(n_capt))^-1;
    J = invG*M;

if nargout > 1
    varargout{1} = param1;
end
return
