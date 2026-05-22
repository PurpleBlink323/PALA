function IQ_enh = LCNEnh(IQ,sigma)
    % LCN
    IQ = abs(IQ);
    eps0  = 1e-6;
    out_lcn = zeros(size(IQ), 'like', double(IQ));
    parfor k = 1:size(IQ,3)
        I  = double(IQ(:,:,k));
        mu = imgaussfilt(I, sigma);
        sd = sqrt(imgaussfilt((I - mu).^2, sigma) + eps0);
        temp=(I - mu) ./ sd;
        out_lcn(:,:,k) = temp;    % LCN
    end
    out_lcn = max(out_lcn, 0);
    IQ_enh = out_lcn;

%     % Binerize
%     Amin = 20;
%     Imin = 0.05;
%     out_bi = zeros(size(out_lcn), 'like', double(out_lcn));
%     out_lcn(out_lcn<0.2)=0;
%     out_lcn = rescale(out_lcn, 0,1);
%     % adapthisteq
%     parfor k = 1:size(out_lcn,3)
%         Iraw  = double(out_lcn(:,:,k));
%         I = imgaussfilt(Iraw,2);
%         T0  = graythresh(I);
%         T   = min(1, 1*T0);
%         BW = imbinarize(I,T);
%         CC = bwconncomp(BW, 8);
%         S  = regionprops(CC, Iraw, 'Area','MeanIntensity');
%         A =  vertcat(S.Area);
%         I = vertcat(S.MeanIntensity);
%         keep = (A >= Amin) &  (I >= Imin);
%         BW_keep = false(size(BW));
%         BW_keep(cat(1, CC.PixelIdxList{keep})) = true;
%     %     BW = bwareaopen(BW, 10);
%     %     BW = imopen(BW, strel('disk',2));
%     %     BW = bwareaopen(BW, 40);
%         I_global= BW_keep.*Iraw;
%     %     I = imgaussfilt(I_global,2);
%     %     BW2 = imbinarize(I,"adaptive","Sensitivity",0.4);
%     %     I_bi = BW2.*I_global;
%     %     out_bi(:,:,k) = I_bi;    % LCN
%         out_bi(:,:,k) = I_global;
%     end
%     IQ_enh = out_bi;
%     IQ_enh(~isfinite(IQ_enh)) = 0;
end