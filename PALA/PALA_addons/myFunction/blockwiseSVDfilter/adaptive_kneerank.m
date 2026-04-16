function k0 = adaptive_kneerank(s, kmin, kmax, win)

s = double(s(:));
n = numel(s);

kmin = max(2, min(kmin, n));
kmax = max(kmin, min(kmax, n));

if nargin < 4 || isempty(win)
    win = max(5, 2*floor(n/50)+1);   % odd window, ~2% of length, at least 5
end
win = min(win, n - mod(n+1,2));      % keep win <= n, and odd if possible
if mod(win,2)==0, win = win-1; end
win = max(3, win);

ls = log(s + eps);
ls = movmean(ls, win, 'Endpoints','shrink');

d1 = diff(ls);
d2 = diff(d1);

lo = max(1, kmin-1);
hi = min(numel(d2), kmax-1);

[~, idx] = max(d2(lo:hi));
k0 = (lo + idx - 1) + 1;

k0 = min(max(k0, kmin), kmax);

end