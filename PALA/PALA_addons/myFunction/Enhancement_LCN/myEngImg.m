function IQ_enh = myEngImg(IQ,sigma)
    % LCN
    IQ = abs(IQ);
    eps0  = 1e-6;
    out_lcn = zeros(size(IQ), 'like', double(IQ));
    parfor k = 1:size(IQ,3)
        I  = double(IQ(:,:,k));
        mu = imgaussfilt(I, sigma);
        sd = sqrt(imgaussfilt((I - mu).^2, sigma) + eps0);
        temp=(I - mu) ./ sd;
        out_lcn(:,:,k) = temp;
    end
    out_lcn = max(out_lcn, 0);
    IQ_enh = out_lcn;
end