function [dy, dx] = subpixel_peak_quadratic(p)
% 2D quadratic peak refinement around the center of a small patch.
% Assumes peak is at center element of p (size 3x3 ideally, but works with >=3).
[ny, nx] = size(p);
cy = ceil(ny/2);
cx = ceil(nx/2);

dy = 0; dx = 0;

if cy > 1 && cy < ny
    y = [p(cy-1,cx), p(cy,cx), p(cy+1,cx)];
    denom = (y(1) - 2*y(2) + y(3));
    if abs(denom) > 1e-12
        dy = 0.5*(y(1) - y(3)) / denom;
    end
end

if cx > 1 && cx < nx
    x = [p(cy,cx-1), p(cy,cx), p(cy,cx+1)];
    denom = (x(1) - 2*x(2) + x(3));
    if abs(denom) > 1e-12
        dx = 0.5*(x(1) - x(3)) / denom;
    end
end

dy = max(min(dy, 1), -1);
dx = max(min(dx, 1), -1);

end
