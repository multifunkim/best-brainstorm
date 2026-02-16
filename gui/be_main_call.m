function [varargout] = be_main(varargin)
% BE_MAIN calls the BEst package for solving inverse problems using MEM.
% This function dirrectly call be_main_call
%
% See @be_main_call for a description of the input / output
% -------------------------------------------------------------------------
%
% LATIS team, 2012
%
% ==============================================
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
%%
    
    % ====      CALL THE PACKAGE      ==== %
    if nargout == 1
        Results             =   be_main_call(varargin{:});
        varargout{1}        =   Results;

    elseif nargout == 2
        [Results, OPTIONS]  =   be_main_call(varargin{:});
    
        varargout{1}        =   Results;
        varargout{2}        =   OPTIONS;
        
    else
        error('MEM error : Invalid call to be_main\n')
    end

end