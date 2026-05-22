function cmap = blueGreenRedColormap(nColors)
    if nargin < 1
        nColors = 256;
    end

    nColors = max(2, round(nColors));
    blue = [0.05 0.20 0.85];
    green = [0.10 0.75 0.20];
    red = [0.90 0.05 0.05];

    halfPoint = ceil(nColors/2);
    firstHalf = [linspace(blue(1), green(1), halfPoint)', ...
        linspace(blue(2), green(2), halfPoint)', ...
        linspace(blue(3), green(3), halfPoint)'];
    secondHalf = [linspace(green(1), red(1), nColors - halfPoint + 1)', ...
        linspace(green(2), red(2), nColors - halfPoint + 1)', ...
        linspace(green(3), red(3), nColors - halfPoint + 1)'];

    cmap = [firstHalf; secondHalf(2:end, :)];
end
