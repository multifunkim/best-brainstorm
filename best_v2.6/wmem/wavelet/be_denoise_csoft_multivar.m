function [WDataDen,OPTIONS] = be_denoise_csoft_multivar(...
    wavdata, info_extension, wavscale, roomnoise, OPTIONS)
% Garrote shrinkage with the possibility to use an extra recording to estimate the noise level.
%
%   INPUTS: 
%       -   w       :   wavelet transform
%       -   OPTIONS :   options structure
%
%   OUTPUTS: 
%       -   dw      :   denoised transform
%       -   OPTIONS :   options structure
%
%% ==============================================   
% Copyright (C) 2012 - LATIS Team
%
%  Authors: JM Lina, 2012, jan 1st
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

    % 0=hard; 1=soft; 2=garrote
    thresh_type     = 2;
    VarRobustEst    = 1;
    
    if OPTIONS.optional.verbose
        fprintf('%s: wavelet denoising: threshold computed on each scale (garrote) \n',OPTIONS.mandatory.pipeline );
    end

    % The data size without zero padding added to reach the dyadic length
    RealDataSize2Den    = info_extension.end-info_extension.start+1;
    % The number of zero padding added to reach the dyadic length
    NbZeroPad           = size(wavdata,2)-RealDataSize2Den;
    
    % Wavelet transform the roomnoise if available
    if ~isempty(roomnoise)
        if size(roomnoise,2)<RealDataSize2Den
            error('%s: wavelet denoising: Room noise recording must be at least as long as the data recording\n',OPTIONS.mandatory.pipeline );
        end
        % we then wavelet transform the data (that are xtended to the next power 2)
        [roomnoise]     = be_extended_dyadic(roomnoise(:,1:RealDataSize2Den));
        Data            = roomnoise;
        if OPTIONS.wavelet.vanish_moments == 0
        filtre = MakeONFilter('Haar');
        else
        filtre = MakeONFilter('Daubechies',2*OPTIONS.wavelet.vanish_moments+2);
        end
        [Ns,No] = size(Data);
        Nj = fix(log2(No));
        Noff = min(Nj-1,3);
        WData = zeros(size(Data));
        for i = 1:Ns;
            WData(i,:) = FWT_PO(Data(i,:),Noff,filtre);
        end
        SData(:,:) = WData(:,1:No/2^(Nj-Noff));
        WData(:,1:No/2^(Nj-Noff)) = 0.0;        
        wavbsl          = WData;
    end

    % Init
    N_level = size(OPTIONS.automatic.scales,2);
    [Nc,Nw] = size(wavdata);
    dw = cell(N_level,1);
    killed =[];

    % Compute the white matrix to decorrelate sensors
    % Compute the noise variance to init the threshold
    for i_sc=1:size(OPTIONS.automatic.scales,2)

        WDatat_sc               = wavdata(:,end/(2^i_sc)+1:end/(2^(i_sc-1)));
        CovData                 = cov(WDatat_sc',1);    
        %  U(column)*S(i,i)*V(line)
        [svd_u,svd_d,svd_v]     = svd(CovData);            
        diagD                   = diag(svd_d);
        EnergyConst             = 1;                
        accsumD                 = sqrt(cumsum(diagD.^2)/sum(diagD.^2));
        comp                    = find(accsumD>=EnergyConst,1,'first');
        % Cell because the number of component changes             
        white_mat{i_sc}         = svd_u(:,1:comp)';  
        
        % Index to take only the real data without zero padding
        i_NoPad_str = round(NbZeroPad/(2^(i_sc+1))+1);
        i_NoPad_end = round(size(WDatat_sc,2)-NbZeroPad/(2^(i_sc+1)));
        
        % Compute the lambda (noise variance) on the roomnoise if available
        if ~isempty(roomnoise)
            % reference (U mask) to init sigma
            bsl_ref             = white_mat{i_sc} * wavbsl(:,end/2^i_sc+1:end/(2^(i_sc-1)));  
            bsl_ref_NoPad       = bsl_ref(:,i_NoPad_str:i_NoPad_end);
            % Compute the var on bsl with the new electrode
            if VarRobustEst==0
                diag_svd{i_sc}      = var(bsl_ref_NoPad,0,2); 
            % Compute the variance with the robust estimator
            else
%                 diag_svd{i_sc}      = (median(abs(bsl_ref_NoPad),2)/0.6745).^2;
                medcap              = repmat(median(bsl_ref_NoPad,2),1,size(bsl_ref_NoPad,2));
                diag_svd{i_sc}      = (median(abs(bsl_ref_NoPad-medcap),2)/0.6745).^2;
            end
        else
            % Take the var of the SVD
            if VarRobustEst==0
                diag_svd{i_sc} = diagD(1:comp);
            % Compute the variance with the robust estimator    
            else
                act_ref             = white_mat{i_sc} * WDatat_sc;
                act_ref_NoPad       = act_ref(:,i_NoPad_str:i_NoPad_end);
%                 diag_svd{i_sc}  = (median(abs(act_ref_NoPad),2)/0.6745).^2;
                medcap              = repmat(median(act_ref_NoPad,2),1,size(act_ref_NoPad,2));
                diag_svd{i_sc}      = (median(abs(act_ref_NoPad-medcap),2)/0.6745).^2;                
            end
        end
    end

    for iv = 1:N_level      
    
        % Basis change
        wDec    = white_mat{iv} * wavdata(:,1+end/2^iv:end/2^(iv-1));
        NbComp  = size(wDec,1);
        NbCoeff = round(size(wDec,2)-NbZeroPad/(2^(iv)));
            
        for icomp = 1:NbComp
            thresh   = sqrt(2*log(NbCoeff)*diag_svd{iv}(icomp));                
            wi = wDec(icomp,:);
            % d = |wi|-thresh
            d  = (abs(wi) - repmat(thresh,1,length(wi)));
            %**************************************************
            % 0=hard; 1=soft; 2=garrote
            %**************************************************
            % Soft: sign(wi)*(|wi|-thresh)_d+
            if thresh_type == 1
                k       = d;
                k(d<=0) = 0.00;
                dwi     = sign(wi).*k;                        
            % Garrot: (wi-thresh^2/wi)_d+
            elseif(thresh_type==2)
                k       = wi-repmat(thresh,1,length(wi)).^2./wi;
                k(d<=0) = 0.00;
                dwi     = k;
            % Hard: wi_d+    
            else
                k       = wi;
                k(d<=0) = 0.00;
                dwi     = k;
            end
%             killed(icomp,iv) = 100*(sum(d<=0)-sum(abs(wi)<eps))/length(wi);
            i_NoPad_str = round(NbZeroPad/(2^(iv+1))+1);
            i_NoPad_end = round(size(d,2)-NbZeroPad/(2^(iv+1)));
            killed(icomp,iv) = 100*(sum(d(i_NoPad_str:i_NoPad_end)<=0)...
                -sum(abs(wi(i_NoPad_str:i_NoPad_end))<eps))/NbCoeff;
            dw{iv}(icomp,:)  = dwi;
        end
        mean_kill(1,iv) = sum(killed(:,iv))/size(diag_svd{iv},1);
    end
    OPTIONS.automatic.scales = [OPTIONS.automatic.scales ; mean_kill];
    if OPTIONS.optional.verbose
        disp([OPTIONS.mandatory.pipeline ', wavelet denoising:']);
        if isempty(roomnoise)
            disp([OPTIONS.mandatory.pipeline ,'** Noise covariance denoising ***\n']);
        end        
        for j=1:size(OPTIONS.automatic.scales,2)
            fprintf(' j=%d (%d%% to 0)',j,fix(OPTIONS.automatic.scales(3,j)));
            if mod(j,3)==0, fprintf('\n'); else fprintf(','); end;
        end
        fprintf('\n');
    end
    
    % Give back correlation
    WDataDen = zeros(size(wavdata));
    for iv = 1:N_level
    	WDataDen(:,1+Nw/2^iv:Nw/2^(iv-1)) = white_mat{iv}' * dw{iv};
    end
    
%     % To plot the denoised activity but not the denoised room noise
%     if ~isempty(roomnoise)
%         if OPTIONS.optional.verbose
%            figure('name','Signal denoised');
%            filtre          = MakeONFilter('Daubechies',2*OPTIONS.wavelet.vanish_moments+2);
%            % Inverse Wavelet Transform of the roomnoise
%             max_decomp           = fix(log2(size(WDataDen,2)));
%             StopBefEnd_decomp    = min(max_decomp-1,3);
%             [Ns,No]              = size(WDataDen);
%             Nj                   = fix(log2(No));
%             Noff                 = min(Nj-1,3);        
%             WDataDen(:,1:No/2^(Nj-Noff)) = wavscale;
%             for i = 1:size(WDataDen,1);
%                 TimeSeries_sk(i,:) = iwt_po(WDataDen(i,:),StopBefEnd_decomp,filtre);
%             end
%     %        plot(OPTIONS.mandatory.DataTime,TimeSeries_sk'); 
%             plot(TimeSeries_sk'); 
%     %        xlim([OPTIONS.mandatory.DataTime(1) OPTIONS.mandatory.DataTime(end)]);
%            ylim([-max(max(TimeSeries_sk)) max(max(TimeSeries_sk))]);
%         end
%     end
    
end
