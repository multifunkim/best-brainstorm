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

    color_lookup = build_color_lookup(obj, OPTIONS, iMod);

    render_lod(ax, color_lookup);  % initial draw

    addlistener(ax, 'XLim', 'PostSet', @(~,~) render_lod(ax, color_lookup));
end


function color_lookup = build_color_lookup(obj, OPTIONS, iMod)
    Tmin = obj.t0 - (obj.info_extension.start - 1) / OPTIONS.automatic.sampling_rate;
    Tmax = Tmin + (size(obj.data{iMod}, 2) - 1) / OPTIONS.automatic.sampling_rate;
    N    = size(obj.data{iMod}, 2);
    T    = Tmax - Tmin;

    MMM       = colormap(jet(size(OPTIONS.automatic.selected_values{iMod}, 2)));
    MMM       = MMM(end:-1:1, :);
    selection = OPTIONS.automatic.Modality(iMod).selected_jk;
    max_scale = max(selection(2,:));

    color_lookup = struct();
    color_lookup.max_scale = max_scale;
    color_lookup.T         = T;
    color_lookup.N         = N;
    color_lookup.Tmin      = Tmin;
    color_lookup.Tmax      = Tmax;

    % One array per scale
    for sj = 1:max_scale
        bj_fine  = find(selection(2,:) == sj);
        if isempty(bj_fine)
            color_lookup.scales(sj).fine_color_array = [];
            color_lookup.scales(sj).fine_box_len     = T / N * 2^sj;
            continue
        end

        fine_val     = selection(3, bj_fine);
        fine_box_len = T / N * 2^sj;
        max_fine_idx = ceil(T / fine_box_len);

        [sorted_val, I] = sort(fine_val);
        color_scale     = MMM(bj_fine, :);
        color_scale     = color_scale(I, :);

        fine_color_array = nan(max_fine_idx, 3);
        for k = 1:length(sorted_val)
            fine_color_array(sorted_val(k), :) = color_scale(k, :);
        end

        color_lookup.scales(sj).fine_color_array = fine_color_array;
        color_lookup.scales(sj).fine_box_len     = fine_box_len;
    end
end


function render_lod(ax, color_lookup)
    delete(findobj(ax, 'Tag', 'lod_boxes'));

    displayed_time  = xlim(ax);
    displayed_scale = ylim(ax);
    view_width      = displayed_time(2) - displayed_time(1);
    ax_width_px     = getpixelposition(ax);
    ax_width_px     = ax_width_px(3);

    T         = color_lookup.T;
    N         = color_lookup.N;
    Tmin      = color_lookup.Tmin;
    max_scale = color_lookup.max_scale;
    e         = 0.05;
    merge_threshold_px = 2.0;

    sBox = struct('Vertices', [], 'Faces', [], 'FaceVertexCData', [], ...
                  'FaceColor', 'flat', 'EdgeColor', 'none');
    iBox = 1;

    for sj = 1:max_scale
        if (sj + 0.5) < displayed_scale(1) || (sj - 0.5) > displayed_scale(2)
            continue
        end

        fine_color_array = color_lookup.scales(sj).fine_color_array;
        if isempty(fine_color_array), continue; end

        % Find coarsest render scale
        render_sj = sj;
        while render_sj < max_scale
            box_px = (T / N * 2^render_sj) / view_width * ax_width_px;
            if box_px >= merge_threshold_px
                break
            end
            render_sj = render_sj + 1;
        end

        box_length     = T / N * 2^render_sj;
        box_width      = 1 - 2*e;
        n_render_boxes = ceil(T / box_length);
        ratio          = 2^(render_sj - sj);

        for rb = 1:n_render_boxes
            x0 = Tmin + (rb - 1) * box_length;
            x1 = x0 + box_length;

            if x1 < displayed_time(1) || x0 > displayed_time(2)
                continue
            end

            fine_start = (rb - 1) * ratio + 1;
            fine_end   = min(rb * ratio, size(fine_color_array, 1));

            chunk = fine_color_array(fine_start:fine_end, :);
            colors_in_box = chunk(~isnan(chunk(:,1)), :);

            if isempty(colors_in_box), continue; end

            avg_color = mean(colors_in_box, 1);
            y0 = sj - box_width;

            sBox.Vertices(end+1, :) = [x0, y0            ];
            sBox.Vertices(end+1, :) = [x1, y0            ];
            sBox.Vertices(end+1, :) = [x1, y0 + box_width];
            sBox.Vertices(end+1, :) = [x0, y0 + box_width];
            sBox.Faces(end+1, :)    = [iBox, iBox+1, iBox+2, iBox+3, iBox];
            sBox.FaceVertexCData(end+1, :) = avg_color;
            iBox = iBox + 4;
        end
    end

    if ~isempty(sBox.Vertices)
        patch(ax, 'Vertices',        sBox.Vertices, ...
                  'Faces',           sBox.Faces, ...
                  'FaceVertexCData', sBox.FaceVertexCData, ...
                  'FaceColor',       'flat', ...
                  'EdgeColor',       'none', ...
                  'Tag',             'lod_boxes');
    end
end
