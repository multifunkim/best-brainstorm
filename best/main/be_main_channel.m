function [OPTIONS] = be_main_channel(HeadModel, OPTIONS)
% BE_MAIN_CHANNEL retrieves the indices of channels for each modality contained
%   in OPTIONS.DataTypes. The main objective is to fill OPTIONS.Modality with
%   the appropriate information
%
% Inputs:
% -------
%
%	HeadModel	:	structure of HeadModel used in brainstorm
%	obj			:	MEM obj structure
%   OPTIONS     :   structure (see bst_sourceimaging.m)
%
%
% Outputs:
% --------
%
%   OPTIONS     :   Updated options fields
%
% -------------------------------------------------------------------------
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


% ====== we initialize the Modality basic structure
% Number of modalities:
nMod = numel(OPTIONS.mandatory.DataTypes);
for ii = 1:nMod
    OPTIONS.automatic.Modality(ii).name           = OPTIONS.mandatory.DataTypes{ii};
    OPTIONS.automatic.Modality(ii).data           = [];
    OPTIONS.automatic.Modality(ii).covariance     = [];
    OPTIONS.automatic.Modality(ii).channels       = [];
    OPTIONS.automatic.Modality(ii).baseline       = [];
    OPTIONS.automatic.Modality(ii).paramH0        = [];
    OPTIONS.automatic.Modality(ii).mspDATA        = struct;
    OPTIONS.automatic.Modality(ii).emptyroom      = [];
end
   
for ii = 1 : nMod
    
    %% ============================ CHANNELS =========================== %%
    % retrieve channels (i.e get indices of channels for all modalities)
    % the order will be the order the modalities have been listed in
    % OPTIONS.DataTypes
    
    CH = find(strcmpi(OPTIONS.mandatory.ChannelTypes, OPTIONS.mandatory.DataTypes{ii}));
    if isempty(CH)
        error(['MEM > Unable to find appropriate data. No '  OPTIONS.mandatory.DataTypes{ii} ' channels found.']);
    end


    if size(CH,1) == 1
        OPTIONS.automatic.Modality(ii).channels   = CH';
    else
        OPTIONS.automatic.Modality(ii).channels   = CH;
    end
    
    %% ============================== DATA ============================= %%
    if isfield(OPTIONS.mandatory, 'Data') && ~isempty(OPTIONS.mandatory.Data)
        OPTIONS.automatic.Modality(ii).data = OPTIONS.mandatory.Data( CH,: );
    end

    % Case of a ridge-filtered signal
    if isfield(OPTIONS.optional, 'iData') && ~isempty(OPTIONS.optional.iData)
        OPTIONS.automatic.Modality(ii).idata          =   OPTIONS.optional.iData( CH,: );
    end
    
    % Case of a wavelet-adaptive clustering
    if isfield( OPTIONS.automatic, 'mspDATA' ) && ~isempty( fieldnames(OPTIONS.automatic.mspDATA) )
        OPTIONS.automatic.Modality(ii).mspDATA.FRQs   =   OPTIONS.automatic.mspDATA.FRQs;
        OPTIONS.automatic.Modality(ii).mspDATA.Time   =   OPTIONS.automatic.mspDATA.Time;
        OPTIONS.automatic.Modality(ii).mspDATA.F      =   OPTIONS.automatic.mspDATA.F( CH,: );
    end
    
    
    %% ============================ BASELINE =========================== %%
    if ~isempty(OPTIONS.optional.Baseline) 
        OPTIONS.automatic.Modality(ii).baseline = OPTIONS.optional.Baseline( CH,: );
    end

    %% ============================ EMPTY ROOM =========================== %%
    if isfield(OPTIONS.automatic, 'Emptyroom_data') 
        ERD     =   OPTIONS.automatic.Emptyroom_data(CH,: );
        if any(ERD(:))
            % emptyroom data available for this modality
            OPTIONS.automatic.Modality(ii).emptyroom = ERD;
        end
    end
        
    %% =========================== COVARIANCE ========================== %%
    if ~isempty(OPTIONS.solver.NoiseCov)
        for i_sc = 1: size(OPTIONS.solver.NoiseCov,3)
            OPTIONS.automatic.Modality(ii).covariance(:,:,i_sc) =  OPTIONS.solver.NoiseCov(CH, CH, i_sc);
        end
    end
    
    %% ============================== GAIN ============================= %%
    if isfield(HeadModel, 'Gain') && ~isempty(HeadModel.Gain)          
        OPTIONS.automatic.Modality(ii).gain = HeadModel.Gain(CH,:);
     end      
    
    %% ============================ MSP data =========================== %%
    % ====== we pick the temporal data needed for MSP
    % This only applies to rMEM where OPTIONS.mandatory.Data be_main_channel.mis complex
    if ~numel( fieldnames(OPTIONS.automatic.Modality(ii).mspDATA) ) && isfield( OPTIONS, 'temporary' ) && isfield( OPTIONS.temporary, 'mspDATA' )
        OPTIONS.automatic.Modality(ii).mspDATA      = OPTIONS.temporary.mspDATA;
        OPTIONS.automatic.Modality(ii).mspDATA.F    = OPTIONS.automatic.Modality(ii).mspDATA.F( CH, : );
    end    
    
end

% Remove used fields
OPTIONS.mandatory   =   rmfield(OPTIONS.mandatory,  'Data' );
if isfield(OPTIONS.optional,  'Baseline' )
    OPTIONS.optional    =   rmfield(OPTIONS.optional,   'Baseline');
end
if isfield(OPTIONS.automatic,  'mspDATA' )
    OPTIONS.automatic   =   rmfield(OPTIONS.automatic,  'mspDATA' );
end

end

