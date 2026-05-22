function IQ_filt = highpassEnhanceIQ(IQ, paras)
    ULM = paras.ULM;
    if ULM.butter.CutoffFreq <= 0 || ULM.butter.CutoffFreq >= ULM.butter.samplingFreq/2
        error('ULM.butter.CutoffFreq must be between 0 and the Nyquist frequency.');
    end
    [but_b,but_a] = butter(4,ULM.butter.CutoffFreq/(ULM.butter.samplingFreq/2),'high');
    IQ_filt = filter(but_b,but_a,IQ,[],3);
    IQ_filt(~isfinite(IQ_filt))=0;
end
