function [obj, OPTIONS] = be_main_wmem_scaling(obj, OPTIONS)
% BE_MAIN_MEM sets the appropriate options for the MEM 
% accroding to the chosen MEM pipeline
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
%       -   OPTIONS
%       - obj
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

    obj.data =  obj.scaling_data;
    
    Nj                  = fix(log2(size(obj.data,2)));
    max_scale           = OPTIONS.automatic.scales(1,end);
    iBoxes_max_scale    = OPTIONS.automatic.selected_samples(2,:)==max_scale;
    selected_k = OPTIONS.automatic.selected_samples(3,iBoxes_max_scale);
    
    selected_samples = zeros(6,sum(iBoxes_max_scale));
    selected_samples(1,:) = selected_k+1;
    selected_samples(2,:) = Nj;
    selected_samples(3,:) = selected_k;
    
    OPTIONS.automatic.selected_samples = selected_samples;
    
    [obj.ImageGridAmp, OPTIONS] = be_launch_mem(obj, OPTIONS);
    [obj, OPTIONS] = be_unormalize_and_units(obj, OPTIONS);
    
    obj.inv_proj = be_wavelet_inverse_projection(obj, OPTIONS);

end
