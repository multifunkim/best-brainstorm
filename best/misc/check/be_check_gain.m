function [indices, G] = be_check_gain(G, type)
% Check for NaN in the lead field matrix
% NOTE (CH) Oct 31, 2011: Gain matrix from Brainstorm may contain rows of 
% NaNs for some reason, so it's important to make that check.
%
%   INPUTS:
%       -   G       : gain matrix
%       -   type    : modality
%
%   OUTPUTS:
%       -   indices : rejected sources
%       -   G       : clean gain matrix
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

indices = 1 : size(G,2);
if any(isnan(G))
    disp('MEM >>> Warning:')
    disp(['MEM >>> ' type 'gain for some sources was incorrect (NaN)'])
    disp('MEM >>> concerned sources were removed')
    
    idx = logical( sum(isnan(G)) );
    G(idx) = 0; % 
    indices(idx) = [];
end

end