function [Data, OPTIONS] = be_wavelet_inverse(WData,OPTIONS)
%BE_WAVELET_INVERSE computes the inverse wavelet transform 
%
%   INPUTS:
%       -   WData   :   discrete wavelet transform
%
%   OUTPUTS:
%       -   OPTIONS :   options structure (see be_main.m)
%
%% ==============================================   
% Copyright (C) 2012 - LATIS Team
%
%  Authors: LATIS, 2012
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
[Ns,No] = size(WData);

if ~OPTIONS.automatic.stand_alone
    bst_progress('start', 'wMNE, Computing inverse wavelet transform... ' , 'Computing inverse wavelet transform.... ', 1, Ns);
end
time_it_starts = tic();

if strcmp(OPTIONS.wavelet.type,'RDW')
    
    if OPTIONS.optional.verbose
        fprintf('%s, Wavelab850 inv. wavelet transform (%s%d) ...',OPTIONS.mandatory.pipeline , OPTIONS.wavelet.type, OPTIONS.wavelet.vanish_moments);
    end
    
    if OPTIONS.wavelet.vanish_moments == 0
        filtre = MakeONFilter('Haar');
    else
        filtre = MakeONFilter('Daubechies',2*OPTIONS.wavelet.vanish_moments+2);
    end

    Nj = fix(log2(No));
    Noff = Nj-size(OPTIONS.automatic.scales,2);
    Data = zeros(Ns,No, 'like', WData);
    for i = 1:Ns
        Data(i,:) = IWT_PO(WData(i,:),Noff,filtre);

        if ~OPTIONS.automatic.stand_alone
            bst_progress('inc', 1); 
        end

    end
    
elseif strcmp(OPTIONS.wavelet.type,'rdw')
    
    if OPTIONS.optional.verbose
        fprintf('%s, rdw inverse wavelet transform (%s%d) ...',OPTIONS.mandatory.pipeline , OPTIONS.wavelet.type, OPTIONS.wavelet.vanish_moments);
    end
 
    if OPTIONS.wavelet.vanish_moments > 7
        filtre = 'rdw0';
    else
        filtre = ['rdw' num2str(OPTIONS.wavelet.vanish_moments)];
    end
    
    Njs  = size(OPTIONS.automatic.scales,2);
    
    Data = zeros(Ns,No, 'like', WData);
    for i = 1:Ns
        Data(i,:) =  be_dwsynthesis(full(WData(i,:)), Njs, filtre);

        if ~OPTIONS.automatic.stand_alone
            bst_progress('inc', 1); 
        end
    end
    
end    
time_it_ends = toc(time_it_starts);

if OPTIONS.optional.verbose
    fprintf(' done in %5.2f seconds.\n',time_it_ends);
end

if ~OPTIONS.automatic.stand_alone
    bst_progress('stop');
end

end