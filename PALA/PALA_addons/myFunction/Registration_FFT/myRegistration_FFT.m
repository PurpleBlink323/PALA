function [IQ_reg, dx, dy] = myRegistration_FFT(IQ, refIdx, upsampleFactor, useTissueRef)
% Rigid (translation-only) registration for complex IQ sequence.
% Motion is estimated from envelope images, and applied to complex IQ via Fourier shift.
%
% Inputs
%   IQ             : Nx x Ny x Nt complex
%   refIdx         : reference frame index (default: 1)
%   upsampleFactor : subpixel estimation factor (default: 50; higher = finer, slower)
%   useTissueRef   : if true, use a temporal average of envelopes as reference (default: true)
%
% Outputs
%   IQ_reg : registered IQ (same size/type as IQ)
%   dx, dy : per-frame shifts in pixels (positive dx shifts right, positive dy shifts down)

if nargin < 2 || isempty(refIdx), refIdx = 1; end
if nargin < 3 || isempty(upsampleFactor), upsampleFactor = 50; end
if nargin < 4 || isempty(useTissueRef), useTissueRef = true; end

[Nx, Ny, Nt] = size(IQ);

A = abs(IQ);
A = double(A);

if useTissueRef
    Aref = mean(A, 3);
else
    Aref = A(:,:,refIdx);
end

dx = zeros(Nt,1);
dy = zeros(Nt,1);

IQ_reg = zeros(size(IQ), 'like', IQ);

Fref = fft2(Aref);

for t = 1:Nt
    Ft = fft2(A(:,:,t));

    R = (Fref .* conj(Ft));
    R = R ./ (abs(R) + eps);

    c = real(ifft2(R));

    [~, idx] = max(c(:));
    [py, px] = ind2sub([Nx, Ny], idx);

    if py > Nx/2, py = py - Nx; end
    if px > Ny/2, px = px - Ny; end

    dy0 = py - 1;
    dx0 = px - 1;

    if upsampleFactor > 1
        w = 1;
        y1 = max(1, py-w); y2 = min(Nx, py+w);
        x1 = max(1, px-w); x2 = min(Ny, px+w);

        sub = c(y1:y2, x1:x2);
        [dys, dxs] = subpixel_peak_quadratic(sub);

        dy(t) = dy0 + dys;
        dx(t) = dx0 + dxs;
    else
        dy(t) = dy0;
        dx(t) = dx0;
    end

    IQ_reg(:,:,t) = fourier_shift_2d(IQ(:,:,t), dx(t), dy(t));
end

end