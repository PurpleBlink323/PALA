function IQ_filt = svdEnhanceIQ(IQ, paras)
    ULM = paras.ULM;
    IQ_filt = SVDfilter(IQ,ULM.SVD_cutoff);
    [but_b,but_a] = butter(2,ULM.butter.CutoffFreq/(ULM.butter.samplingFreq/2),'bandpass');
    IQ_filt = filter(but_b,but_a,IQ_filt,[],3);
    IQ_filt(~isfinite(IQ_filt))=0;
    IQ_filt = LCNEnh(IQ_filt,ULM.sigmaLCN);
end