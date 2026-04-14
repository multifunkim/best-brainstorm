function [hp, hptab] = be_display_time_scale_boxes(obj, OPTIONS) 
%be_display_time_scale_boxes displays the discrete wavelet
%representation
%
%   INPUTS:
%       -   obj
%       -   OPTIONS
%
%   OUTPUTS:
%      -    hp
%      -    hptab
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
% parametres: hp , Tmin, Tmax, J, N et boites
% hp : panel handle
% Tmin : time(0)
% Tmax : time(end)
% J : levels
% N : nomber of samples
% TFboxes is a structure .k ans .j are (j,k) coordinates

    hp      = obj.hfig;
    hptab   = obj.hfigtab; 
    
    if ~strcmp(obj.data_type,'discrete_wavelet')
        disp('NO WAVELET DISPLAY');
        return
    end
    
    for ii = 1:length(OPTIONS.mandatory.DataTypes)
    
        hhh  = uitab(hptab,'title', OPTIONS.mandatory.DataTypes{ii});
        hpc  = uipanel('Parent', hhh, ...
                       'Units', 'Normalized', ...
                       'Position', [0.01 0.01 0.98 0.98], ...
                       'FontWeight','demi');
        set(hpc,'Title', 'Time-frequency boxes', 'FontSize', 8);
    
        Tmin = obj.t0 - (obj.info_extension.start-1)/OPTIONS.automatic.sampling_rate;
        Tmax = Tmin + (size(obj.data{ii},2)-1)/OPTIONS.automatic.sampling_rate;

        scales = unique(OPTIONS.automatic.Modality(ii).selected_jk(2,:));
        J    = max(scales);

        ax = axes( 'parent', hpc, ...
                   'outerPosition', [0.01 0.01 0.98 0.98], ...
                   'YTick', 0.5:J-0.5, ...
                   'YTickLabel', num2cell(1:J), ...
                   'Xlim', [Tmin, Tmax], ...
                   'Ylim', [0, J], ...
                   'Box','on');

        %sBox = create_rectangles(obj, OPTIONS, ii);
        %patch(ax, sBox);
        setup_lod_rendering(ax, obj, OPTIONS, ii);
        xlabel(ax, 'time (s)'); ylabel(ax,  'scale j');
        
        continue;

        for scl = 1:length(OPTIONS.wavelet.selected_scales)

            sj = OPTIONS.wavelet.selected_scales(scl);
            bj = find(OPTIONS.automatic.Modality(ii).selected_jk(2,:)==sj);
            tt = OPTIONS.automatic.Modality(ii).selected_jk(6,bj);
            vv = OPTIONS.automatic.selected_values{ii}(2,bj);
            tv = OPTIONS.automatic.selected_values{ii}(3,bj);

            if isempty(tt)
                % if there is no selected box for that scale, we skip. 
                continue;
            end

            hhh = uitab(hptab,'title', [' scale ' num2str(OPTIONS.wavelet.selected_scales(scl)) ' ']);
            hpc = uipanel(  'Parent', hhh, ...
                            'Units', 'Normalized', ...
                            'Position', [0.01 0.01 0.98 0.98], ...
                            'FontWeight', 'demi');

            set(hpc,'Title', ' Wavelet coefficients (% of power) ', 'FontSize', 8);
            ax = axes('parent',hpc, 'outerPosition',[0.01 0.01 0.98 0.98]);

            hold(ax,'on')
            stem(ax, tt(tv==0), vv(tv==0), 'x', 'filled', 'markersize', 8, 'MarkerFaceColor', 'black', 'Color','black'); 
            stem(ax, tt(tv==1), vv(tv==1), 'o', 'filled', 'markersize', 8, 'MarkerFaceColor', 'red', 'Color','red'); 
            hold(ax,'off')
        end

        drawnow
    end

end


function sBox = create_rectangles(obj, OPTIONS, iMod)

    Tmin = obj.t0 - (obj.info_extension.start-1)/OPTIONS.automatic.sampling_rate;
    Tmax = Tmin + (size(obj.data{iMod},2)-1)/OPTIONS.automatic.sampling_rate;
    N    = size(obj.data{iMod},2);
    T    = Tmax - Tmin;
    e    = 0.05;
    MMM         = colormap(jet(size(OPTIONS.automatic.selected_values{iMod},2)));
    MMM         = MMM(end:-1:1, :);
    selection   = OPTIONS.automatic.Modality(iMod).selected_jk;

    sBox = struct('Vertices', [],'Faces',[],  'FaceVertexCData', [],'FaceColor','flat', 'EdgeColor', 'none');
    iBox = 1;

    for sj = 1:max(OPTIONS.automatic.Modality(iMod).selected_jk(2,:))

        bj = find(OPTIONS.automatic.Modality(iMod).selected_jk(2,:)==sj);
        tt = OPTIONS.automatic.Modality(iMod).selected_jk(6,bj);

        if isempty(tt)
            % if there is no selected box for that scale, we skip. 
            continue;
        end
        
        box_length = T/N*2^sj;
        box_width  = 1-2*e;

        [val, I]  = sort(selection(3,bj));

        color_scale = MMM(bj, :);
        color_scale = color_scale(I, :);
    
        for b=1:length(I)

            sBox.Vertices(end+1, :) = [Tmin + ((val(b)-1) * box_length), sj - box_width] + [ 0, 0];
            sBox.Vertices(end+1, :) = [Tmin + ((val(b)-1) * box_length), sj - box_width] + [ box_length, 0];
            sBox.Vertices(end+1, :) = [Tmin + ((val(b)-1) * box_length), sj - box_width] + [ box_length, box_width];
            sBox.Vertices(end+1, :) = [Tmin + ((val(b)-1) * box_length), sj - box_width] + [ 0, box_width];

            sBox.Faces(end+1, :)  = [iBox, iBox + 1, iBox + 2 , iBox + 3, iBox];
            iBox = iBox + 4;

            sBox.FaceVertexCData(end+1, :) = color_scale(b, :);
        end
    end
end


function setup_lod_rendering(ax, obj, OPTIONS, iMod)
    % Initial draw
    render_lod(ax, obj, OPTIONS, iMod);
    
    % Re-render on zoom/pan
    addlistener(ax, 'XLim', 'PostSet', @(~,~) render_lod(ax, obj, OPTIONS, iMod));
end

function render_lod(ax, obj, OPTIONS, iMod)
    delete(findobj(ax, 'Tag', 'lod_boxes'));
    
    xlim_range  = ax.XLim;
    view_width  = xlim_range(2) - xlim_range(1);
    fig = ancestor(ax, 'figure');
    fig_units_orig = fig.Units;
    fig.Units = 'pixels';
    fig_pos = fig.Position;
    fig.Units = fig_units_orig;  % restore original units
    
    ax_units_orig = ax.Units;
    ax.Units = 'normalized';
    ax_norm_width = ax.Position(3);
    ax.Units = ax_units_orig;  % restore

ax_width_px = ax_norm_width * fig_pos(3);    
    Tmin = obj.t0 - (obj.info_extension.start - 1) / OPTIONS.automatic.sampling_rate;
    Tmax = Tmin + (size(obj.data{iMod}, 2) - 1) / OPTIONS.automatic.sampling_rate;
    N    = size(obj.data{iMod}, 2);
    T    = Tmax - Tmin;
    e    = 0.05;
    
    MMM       = colormap(jet(size(OPTIONS.automatic.selected_values{iMod}, 2)));
    MMM       = MMM(end:-1:1, :);
    selection = OPTIONS.automatic.Modality(iMod).selected_jk;
    
    sBox = struct('Vertices', [], 'Faces', [], 'FaceVertexCData', [], ...
                  'FaceColor', 'flat', 'EdgeColor', 'none');
    iBox = 1;
    
    % Minimum pixel width below which we merge adjacent boxes
    merge_threshold_px = 5;
    
    displayed_scaled = ylim(ax);
    displayed_time = xlim(ax);

    for sj = 1:max(OPTIONS.automatic.Modality(iMod).selected_jk(2,:))
        
        if (sj + 0.5) < min(displayed_scaled) || ( sj - 0.5 ) > max(displayed_scaled)
            fprintf('skipping %d. Ylim : [%f %f] \n', sj, displayed_scaled(1), displayed_scaled(2))
            continue
        end

        bj = find(OPTIONS.automatic.Modality(iMod).selected_jk(2,:) == sj);
        tt = OPTIONS.automatic.Modality(iMod).selected_jk(6, bj);
        if isempty(tt), continue; end
        
        box_length = T / N * 2^sj;
        box_width  = 1 - 2*e;
        
        [val, I] = sort(selection(3, bj));
        color_scale = MMM(bj, :);
        color_scale = color_scale(I, :);
        
        % Pixel width of a single box in current view
        box_px = box_length / view_width * ax_width_px;
        
        fprintf('sj: %d; box_px %f \n',sj,  box_px)
        if box_px >= merge_threshold_px
            % === FULL DETAIL: individual boxes ===
            for b = 1:length(I)
                x0 = Tmin + (val(b) - 1) * box_length;
                x1 = x0 + box_length;
                y0 = sj - box_width;

                % Skip if box is entirely outside current x view
                if x1 < displayed_time(1) || x0 > displayed_time(2)
                    continue
                end

                sBox.Vertices(end+1, :) = [x0,              y0            ];
                sBox.Vertices(end+1, :) = [x0 + box_length, y0            ];
                sBox.Vertices(end+1, :) = [x0 + box_length, y0 + box_width];
                sBox.Vertices(end+1, :) = [x0,              y0 + box_width];
                sBox.Faces(end+1, :)    = [iBox, iBox+1, iBox+2, iBox+3, iBox];
                sBox.FaceVertexCData(end+1, :) = color_scale(b, :);
                iBox = iBox + 4;
            end
            
        else
            % === MERGED MODE: merge consecutive boxes, but cap merge size ===
            % Target: each merged group should be ~target_px pixels wide
            target_px     = 5;  % merged block minimum visual width in pixels
            boxes_per_group = max(1, round(target_px / box_px));
            
            b = 1;
            while b <= length(I)
                % Find consecutive run starting at b
                run_start_idx = b;
                run_end_idx   = b;
                
                % Extend run: only merge if boxes are consecutive in time index
                while run_end_idx < length(I) && ...
                      val(run_end_idx + 1) == val(run_end_idx) + 1 && ...
                      (run_end_idx - run_start_idx + 1) < boxes_per_group
                    run_end_idx = run_end_idx + 1;
                end
                
                % Average color over the run
                run_len   = run_end_idx - run_start_idx + 1;
                avg_color = mean(color_scale(run_start_idx:run_end_idx, :), 1);
                
                x0         = Tmin + (val(run_start_idx) - 1) * box_length;
                merged_len = run_len * box_length;
                y0         = sj - box_width;
                
                sBox.Vertices(end+1, :) = [x0,              y0            ];
                sBox.Vertices(end+1, :) = [x0 + merged_len, y0            ];
                sBox.Vertices(end+1, :) = [x0 + merged_len, y0 + box_width];
                sBox.Vertices(end+1, :) = [x0,              y0 + box_width];
                sBox.Faces(end+1, :)    = [iBox, iBox+1, iBox+2, iBox+3, iBox];
                sBox.FaceVertexCData(end+1, :) = avg_color;
                iBox = iBox + 4;
                
                b = run_end_idx + 1;
            end
        end
    end
    
    if ~isempty(sBox.Vertices)

        fprintf('Plotting %d boxes \n', size(sBox.Vertices, 1))
        patch(ax, 'Vertices',        sBox.Vertices, ...
                  'Faces',           sBox.Faces, ...
                  'FaceVertexCData', sBox.FaceVertexCData, ...
                  'FaceColor',       'flat', ...
                  'EdgeColor',       'none', ...
                  'Tag',             'lod_boxes');
    end
end