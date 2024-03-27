function OPTIONS = baseline(OPTIONS)
fs=round( 1 / diff( OPTIONS.mandatory.DataTime([1 2]) ) );
no_of_baseline = round(length(OPTIONS.optional.Baseline)/fs);
%Baseline = cell(1,no_of_baseline);
if no_of_baseline>1
    for k=1:no_of_baseline
        base=OPTIONS.optional.Baseline(:,(fs*(k-1)+1):fs*k);
        Baseline(:,:,k) = BEst_baseline_from_signal(base);
    end
else
    Baseline = BEst_baseline_from_signal(OPTIONS.optional.Baseline);
end
OPTIONS.optional.Baseline = Baseline;
OPTIONS.automatic.Modality.baseline = Baseline;
OPTIONS.baseline_shuffle = 1;

    function baseline = BEst_baseline_from_signal(signal)

        % signal is a Ns x No matrix of data
        % baseline is a Ns x No matrix of synthetic
        % data obtained from the signal. It is obtained
        % from the phase resampling of the Fourier
        % transform of the signal. The baseline
        % thus preserves the spectrum of the signal but
        % destroys the temporal coherence.

        % fs: sampling frequency of the signal


        [Ns,No] = size(signal);
        signal  = detrend(signal')';
        qData = zeros(size(signal));
        N = 2^min(10,nextpow2(No));
        randp = 2*pi*rand(1,N);
        randp = 0.5*(randp - flip(randp));
        HANN = hann(N)';
        %%%% RE-Echantillonnage:
        for i = 1:Ns
            %          randp = 2*pi*randn(1,N);
            %      randp = 0.5*(randp - flip(randp));

            uData = resample(signal(i,:),N,No);
            wData = fft(HANN' .* uData',N)';
            wData = wData .* exp(1i*randp);
            wData = real(ifft(wData'));
            qData(i,:) = resample(wData,No,N);
        end
        baseline = qData;


    end
end
end

