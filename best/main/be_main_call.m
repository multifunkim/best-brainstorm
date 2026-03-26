function [varargout] = be_main_call(varargin)
% be_main_call
% This function is depracated. Call be_main instead.
%
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
    
    [varargout{1:nargout}]  = be_main(varargin{1:end});

end