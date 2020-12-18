function [grainSizeum, fileInfo] = GrainSizeSemiAuto(path, pic, varargin)
%NOTE - This requires MATLAB's image processing toolbox

%If you are not part of the Cahoon group at UNC, you will likely have to
%change several parameters in the function below.

% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


filetype='.tif'; %default file type
iterlimit = 100; %how many times do you want to count grains for each image?
for vv = 1:length(varargin)
    if strcmpi(varargin{vv}, 'filetype')
        filetype = varargin{vv+1};
    elseif strcmpi(varargin{vv}, 'limit')
        iterlimit = varargin{vv+1};
    end
end; clear vv

historypath = 'D:\YOUMUSTCHANGE\THISDIRECTORY';

cd(path) %change to that directory


I = imread(strcat(path,'\',pic,filetype)); %read the picture
if numel(I(1,1,:)) >= 3,%Converts pic to grayscale if not already
    I = I(:,:,1:3);
end
I = im2double(I); %convert image to double for processing
OrigPic = figure; %create a figure to host image
imshow(I)%,'InitialMagnification',50) %show the figure




if ~exist(strcat(pic,'.mat'), 'file') %if data file doesn't exist, initialize
    fileInfo = {'path','name','umPerPixel'}; %initialize for output
    GBdata = {'lineCoordsX','lineCoordsY','length(um)','intersections'};
    
    
    umScale = mvdlg('What is the scale in microns (or man for manual input)? ','Scale',[0.4 0.5 .22 .15]); %ask for scale bar (designed for Helios 600 Nanolab Dual Beam microscope)
    if strcmp(umScale{1,1},'man')
        umScale = mvdlg('How many microns per pixel? Or which Zeiss objective used? ','Microns/Px or Objective?',[0.4 0.5 .25 .15]); %In case you're using a different microscope (such as an optical microscope)
        if strcmp(umScale{1,1},'5x')
            umPerPixel = 0.434153387;
        elseif strcmp(umScale{1,1},'10x')
            umPerPixel = 0.217962624;
        elseif strcmp(umScale{1,1},'50x')
            umPerPixel = 0.043346955;
        elseif strcmp(umScale{1,1},'100x')
            umPerPixel = 0.022376736;
        else
            umPerPixel = str2double(umScale{1,1});
        end
    else %if not manual mode, use a function to measure the scale bar (designed for Helios 600 Nanolab Dual Beam microscope)
        umScale = str2double(umScale{1,1});
        umPerPixel = AutoSetScale(I,umScale);    
    end

    
    
    
else %if does exist, load previous data
    load(strcat(pic,'.mat'))
    
    close(OrigPic) %the old OrigPic
    OrigPic = open(strcat(pic,'.fig'));
    
    umPerPixel = fileInfo{2,3};
end


%Now allow for cropping for image analysis
figure; imshow(I); title('Select usable ROI. Double click when done.')
hBox = imrect; %handle for rectangle
maskPosition = wait(hBox); %wait for double click
mask = hBox.createMask; %create binary mask in region selected by rectangle
maskXdisplacement = find(sum(mask,1)>0,1); %used later in plotting where the lines are in relation to original image
maskYdisplacement = find(sum(mask,2)>0,1);
usableROIx = [maskPosition(1) maskPosition(1)+maskPosition(3)];
usableROIy = [maskPosition(2) maskPosition(2)+maskPosition(4)];
[MI,~] = imcrop(I,maskPosition); %actually do the cropping
close
clear hBox mask maskPosition

%Now choose a good size of box
figure; imshow(MI); title('Choose box size capturing multiple grain boundaries. Double click when done.')
hBox = imrect; %handle for rectangle
maskPosition = wait(hBox); %wait for double click
GSboxDim = maskPosition(3:4);
close
clear hBox maskPosition

%modify the usableROIx and y to account for the height of the GSboxDim
usableROIx(2) = usableROIx(2)-GSboxDim(1);
usableROIy(2) = usableROIy(2)-GSboxDim(2);


hFig = figure('Toolbar','none',...
              'Menubar','none'); %make a new figure for doing the line analysis

go = true;
zoom = false;
grainSizeum = 0; %initialization for dialogue box
while go
        
    %Choose a random location for the mask box inside the usable ROI
    maskPosition = [usableROIx(1)+(usableROIx(2)-usableROIx(1))*rand() usableROIy(1)+(usableROIy(2)-usableROIy(1))*rand() GSboxDim(1) GSboxDim(2)];
    [yy, xx] = ndgrid((1:size(I,1)),(1:size(I,2)));
    mask = xx>maskPosition(1) & xx<maskPosition(1)+maskPosition(3) & yy>maskPosition(2) & yy<maskPosition(2)+maskPosition(4); %create binary mask in region selected by rectangle
    maskXdisplacement = find(sum(mask,1)>0,1); %used later in plotting where the lines are in relation to original image
    maskYdisplacement = find(sum(mask,2)>0,1);
    [MI,~] = imcrop(I,maskPosition); %actually do the cropping
%     clear mask maskPosition    
    
    hIm = imshow(MI); %show the masked image in LinePic figure
    
    if zoom
        hSP = imscrollpanel(hFig,hIm); % Handle to scroll panel.
        set(hSP,'Units','normalized',...
                'Position',[0 .1 1 .9])

        % Add a Magnification Box
        hMagBox = immagbox(hFig,hIm);
        pos = get(hMagBox,'Position');
        set(hMagBox,'Position',[0 0 pos(3) pos(4)])
        
        %Add overview tool and move it downwards
        hOv = imoverview(hIm);
        posOv = get(hOv,'Position');
        set(hOv,'Position',[0 300 posOv(3) posOv(4)])

        % Get the scroll panel API to programmatically control the view.
        api = iptgetapi(hSP);
        % Get the current magnification and position.
        mag = api.getMagnification();
        r = api.getVisibleImageRect();

%         api.setMagnification(api.findFitMag()) %Set mag to see entire image
    end
    
    %generate random numbers to represent two pixels to make a line through
    randomX1 = round(rand*size(MI,2));
    randomY1 = round(rand*size(MI,1));
    randomX2 = round(rand*size(MI,2));
    randomY2 = round(rand*size(MI,1));    
    
    %get the slope and intercept from those random points
    slope = (randomY2-randomY1) / (randomX2-randomX1);
    intercept = round(randomY2 - slope*randomX2);
    
    %get points that fit in the masked region
    ptX = 1:0.0001:size(MI,2);
    ptY = slope * ptX + intercept;
    clear slope intercept
    
    pt1idx = find(ptY>=0 & ptY<=size(MI,1),1);
    pt2idx = find(ptY>=0 & ptY<=size(MI,1),1,'last');
    
    ptX1 = ptX(pt1idx);
    ptY1 = ptY(pt1idx);
    ptX2 = ptX(pt2idx);
    ptY2 = ptY(pt2idx);
    
    
    line([ptX1 ptX2],[ptY1 ptY2],'Color','r') %plot the line
    set(hFig, 'Position', get(0, 'Screensize')); %full screen
    %get length of line in nm (and um)
    pixelLength = pdist([ptX1,ptY1;ptX2,ptY2],'euclidean'); 
    umLength = umPerPixel * pixelLength;
    
    intersections = mvdlg('How many grain boundaries? ',sprintf('%i',size(GBdata,1)),[0 .8 .15 .15]);
    if isempty(intersections)
        go = false;
    elseif strcmp(intersections{1,1},'-1')
        %ignore this entry and move on to the next
    elseif strcmp(intersections{1,1},'')
        %ignore this entry and move on to the next
    elseif isempty(intersections{1,1})
        %ignore this entry and move on to next.
    elseif strcmp(intersections{1,1},'zoom')
        zoom = not(zoom);
    else
        intersections = str2double(intersections{1,1});
        xCoords = [ptX1+maskXdisplacement ptX2+maskXdisplacement];
        yCoords = [ptY1+maskYdisplacement ptY2+maskYdisplacement];
        GBdata(end+1,:) = {xCoords,yCoords,umLength,intersections}; %add to final output variable
        
        %Add the line to the original pic and then come back to LinePic
        figure(OrigPic)
        line(xCoords,yCoords,'Color','r')
        figure(hFig)
    end
    
    %Get some statistics
    numIntersections = sum(cell2mat(GBdata(2:end,4)));
    lengthLines = sum(cell2mat(GBdata(2:end,3)));
    numLines = size(GBdata,1)-1;
    grainSizeum = lengthLines/numIntersections;
    fprintf('Grain Size is %0.5f %sm from %i lines\n',grainSizeum,char(181),numLines)
    
    if numLines >= iterlimit
        go = false;
    end
    
    
end; 
clear go intersections %maskXdisplacement maskYdisplacement MI
close(hFig)
clear LinePic





figure(OrigPic)
title(sprintf('%s: %0.2f %sm (n=%i)',strrep(pic,'_','\_'),grainSizeum,char(181),numLines))
saveas(OrigPic,pic)
clipboard('copy',grainSizeum)

fileInfo(2,:) = {path,pic,umPerPixel};
save(pic,'fileInfo','GBdata')


GrainSizeHistory(historypath,path,pic,umPerPixel,lengthLines,numIntersections,numLines)
clear historypath


end