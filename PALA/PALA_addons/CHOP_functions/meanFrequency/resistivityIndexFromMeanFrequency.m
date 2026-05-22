function [RI, peakFrequency, endDiastolicFrequency] = resistivityIndexFromMeanFrequency(MeanFrequencyArray)
    frequencyMagnitude = abs(MeanFrequencyArray);

    peakFrequency = max(frequencyMagnitude, [], 3);
    endDiastolicFrequency = min(frequencyMagnitude, [], 3);

    RI = (peakFrequency - endDiastolicFrequency) ./ peakFrequency;
    RI(peakFrequency <= 0) = 0;
    RI(~isfinite(RI)) = 0;
end
