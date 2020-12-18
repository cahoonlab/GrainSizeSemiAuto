function [ nmPerPixel] = AutoSetScale(image,nmScale)
%AUTOSETSCALE gets the scale from an image taken on a Helios 600 Nanolab Dual Beam microscope
%Based on code written by Joe Christesen (https://cdr.lib.unc.edu/concern/dissertations/8623hz893)


    %Get index of row and column along bottom and right of picture
    subWidth = length(image(1,:)) - 1;    %index of 2nd to last column
    subHeight = length(image(:,1)) - 1;   %index of 2nd to last row

    %Finds index of white from SEM image
    whiteHeight = find(image(subHeight,:) >= .9); %Indices of white pixels in subHeight row
    whiteWidth = find(image(:,subWidth) >= .9);   %Indices of white pixels in subWidth column

    %Finds vertical midpoint of white box containing scale bar
    %Last two indices in whiteWidth are the start and end of that box
    midPoint = ceil((whiteWidth(end - 1) - whiteWidth(end - 2)) / 2 + whiteWidth(end - 2));
    consec = false;
    endColumn = subWidth; %2nd to last column is end column
    startColumn = whiteHeight(end - 1); %Start column is far left of scale bar box

    %Scans columns from right to left 
    %to find consecutive white points in scale bar
    while ~consec
        if endColumn < numel(image(midPoint, :)) && endColumn >= 1
            if image(midPoint, endColumn) >= 0.9 && ...
                    image(midPoint, endColumn-1) >= 0.9
                consec = true;
            end
        end

        if endColumn > numel(image(midPoint, :))
            exception = MException('Outside of picture limits', ...
                ['Could not find consecutive points to locate the scale bar']);
            throw(exception);
        end

        if ~consec
            endColumn = endColumn - 1;
        end
    end

    consec = false;

    %Scans columns from left to right until get consecutive white pixels
    while ~consec
        if startColumn < numel(image(midPoint, :)) && startColumn >= 1
            if image(midPoint, startColumn) >= 0.9 && ...
                    image(midPoint, startColumn + 1) >= 0.9
                consec = true;
            end
        end

        if startColumn > numel(image(midPoint,:))
            exception = MException('Outside of picture limits', ...
                ['Could not find consecutive points to '...
                'locate the scale bar']);
            throw(exception);
        end

        if ~consec
            startColumn = startColumn + 1;
        end
    end

    %Set the value of Nm per pixel and make it visible
    nmPerPixel = nmScale / (endColumn - startColumn);
    
end

