function  be_display_entropy_drops(obj,OPTIONS)
%DISPLAY_ENTROPY_DROPS displays a graphical window with MEM entropy drops at 
% each  iteration
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
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
    
    if ~ismember({obj.hfigtab.Children.Title}, {'ENTROPY'})
        onglet = uitab(obj.hfigtab,'title','ENTROPY');
        
        hpc = uipanel('Parent', onglet, ...
                      'Units', 'Normalized', ...
                      'Position', [0.01 0.01 0.98 0.98], ...
                      'FontWeight','demi');
    
        set(hpc,'Title', 'Entropy drops', 'FontSize',8);
        ax = axes('parent',hpc, 'outerPosition',[0.01 0.01 0.98 0.98]);

        isNew   = true;
    else
        onglet  = obj.hfigtab.Children(strcmp({obj.hfigtab.Children.Title}, {'ENTROPY'}));
        hpc     = onglet.Children;
        ax      = findobj(hpc, 'Type', 'axes');
        isNew   = false;
    end

    if contains(OPTIONS.mandatory.pipeline,{'cMEM','cMNE'})

        DTs = be_closest( OPTIONS.optional.TimeSegment(1), OPTIONS.mandatory.DataTime );
        DTn = be_closest( OPTIONS.optional.TimeSegment(end), OPTIONS.mandatory.DataTime );

        plot(ax,OPTIONS.mandatory.DataTime(DTs:DTn), log(abs(OPTIONS.automatic.entropy_drops)),'-k','linewidth',2);
        xlabel(ax,'time (s)'); 

    else
        selected_samples = OPTIONS.automatic.selected_samples;
        
        if ~isNew
            l = findobj(hpc, 'Type', 'legend');
            scale_legend = l.String;
        else
            scale_legend = {};
        end

        hold(ax, 'on')
        for scl = 1:length(OPTIONS.wavelet.selected_scales)
            sj = OPTIONS.wavelet.selected_scales(scl);
            bj = find(selected_samples(2, :) == sj);
            
            if isempty(bj)
                % if there is no selected box for that scale, we skip. 
                continue;
            end
            
            scale_legend{end+1} = sprintf('Scale %d', sj);
            e = OPTIONS.automatic.selected_values{1}(1, bj);
            plot(ax, log(e) , log(abs(OPTIONS.automatic.entropy_drops(bj))),'-','linewidth',2);
            %plot(ax, bj , log(abs(OPTIONS.automatic.entropy_drops(bj))),'-','linewidth',2);
        end
        legend(ax, scale_legend)
        set(ax, 'XDir','reverse');
        xlabel(ax,'wavelet coefficient (descreasing energy)'); 
    end

    ylabel(ax,'log(|entropy|)'); 

end