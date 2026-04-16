function [IQf, kmap] = blockwiseSVDfilter(IQ, blockSize, overlap, kmin, kmax)
% IQ: [Nx, Ny, Nt], temporal dimension must be the last one
% blockSize: square block side length (e.g., 64)
% overlap: 0~0.95 (e.g., 0.8)
% kmin/kmax: bounds for the estimated tissue rank per block (suggest kmin=2, kmax=round(0.3*Nt))
% Outputs:
%   IQf  : filtered IQ
%   kmap : per-block adaptive k0 (remove 1:k0-1, keep k0:Nt)

initsize = size(IQ);
Nx = initsize(1); Ny = initsize(2); Nt = initsize(3);

if nargin < 2 || isempty(blockSize), blockSize = 64; end
if nargin < 3 || isempty(overlap), overlap = 0.8; end
if nargin < 4 || isempty(kmin), kmin = 2; end
if nargin < 5 || isempty(kmax), kmax = max(kmin, round(0.3*Nt)); end
kmax = min(kmax, Nt);

step = max(1, round(blockSize * (1 - overlap)));

w1 = hann(blockSize);
W = w1 * w1.'; % 2D weighting window to reduce block boundary artifacts
W = W ./ max(W(:)); % normalization

IQf_acc = zeros(Nx, Ny, Nt, 'like', IQ);
W_acc   = zeros(Nx, Ny, 'like', double(IQ));

ix_list = 1:step:(Nx - blockSize + 1);
iy_list = 1:step:(Ny - blockSize + 1);

kmap = zeros(numel(ix_list), numel(iy_list)); % the svd lowrank threashold for each block

for a = 1:numel(ix_list)
    ix = ix_list(a);
    for b = 1:numel(iy_list)
        iy = iy_list(b);

        blk = IQ(ix:ix+blockSize-1, iy:iy+blockSize-1, :);
        X = reshape(blk, blockSize*blockSize, Nt);

        % Right singular vectors are eigenvectors of X'*X
        [Ur, S2] = svd(X'*X, 'econ');
        s = sqrt(max(diag(S2), 0));  % singular values

        % Adaptive selection of tissue rank k0 (knee on log(s))
        k0 = adaptive_kneerank(s, kmin, kmax);

        kmap(a,b) = k0;

        % Remove the first (k0-1) components and keep k0:Nt
        Vt = X * Ur;
        Re = Vt(:, k0:Nt) * Ur(:, k0:Nt)';

        blk_f = reshape(Re, blockSize, blockSize, Nt);

        % Overlap-add accumulation
        for t = 1:Nt
            IQf_acc(ix:ix+blockSize-1, iy:iy+blockSize-1, t) = ...
                IQf_acc(ix:ix+blockSize-1, iy:iy+blockSize-1, t) + blk_f(:,:,t) .* cast(W,'like',IQ);
        end
        W_acc(ix:ix+blockSize-1, iy:iy+blockSize-1) = ...
            W_acc(ix:ix+blockSize-1, iy:iy+blockSize-1) + W;
    end
end

W_acc(W_acc==0) = 1;
for t = 1:Nt
    IQf_acc(:,:,t) = IQf_acc(:,:,t) ./ cast(W_acc, 'like', IQ);
end

IQf = IQf_acc;

end