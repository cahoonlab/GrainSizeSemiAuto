function GrainSizeHistory(historypath,path,pic,nmScale,lengthLines,numIntersections,numLines)
%Facilitates the autosaving of data.

cd(historypath)
load('GBhistory');

lastrow = size(GBhistory,2) + 1;

GBhistory(lastrow).Date = datetime('now');
GBhistory(lastrow).Path = path;
GBhistory(lastrow).Pic = pic;
GBhistory(lastrow).nmScale = nmScale;
GBhistory(lastrow).lengthLines = lengthLines;
GBhistory(lastrow).numIntersections = numIntersections;
GBhistory(lastrow).numLines = numLines;
save('GBhistory','GBhistory')


cd(path)

end

