function Iout = fourier_shift_2d(Iin, dx, dy)
% Apply subpixel translation to complex image using Fourier shift theorem.
[Nx, Ny] = size(Iin);

[u, v] = ndgrid( (0:Nx-1)/Nx, (0:Ny-1)/Ny );
phase = exp(-1j*2*pi*(u*dy + v*dx));
Iout = ifft2( fft2(Iin) .* phase );

end