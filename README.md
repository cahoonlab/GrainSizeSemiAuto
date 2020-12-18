# GrainSizeSemiAuto
A method for measuring average grain size from optical or electron micrographs

There are commercial packages that fulfill the objectives of these scripts much more effectively and automatically. However, when you need a semi-automatic method, this works well.

Essentially, this code displays a micrograph an arbitrary number of times (default is 100), each time displaying a new randomly orientated line across the image and asking the user to input the number of intersecting grain boundaries. At the end, an average grain size is calculated and saved.

To operate, download the scripts to a folder on your PATH. Next, open GrainSizeSemiAuto and insert the directory path into line 29: "historypath = 'D:\YOUMUSTCHANGE\THISDIRECTORY'". This will save your progress automatically. Other changes you may want to make are: default file type (line 19), the number of iterations (line 20), custom scales (lines 52-60), and the dialog box positions (lines 130, 181).

Once the code is ready, run the function with this syntax:
GrainSizeSemiAuto('D:\FOLDERWITHIMAGE','IMAGENAME')

Optional input pairs are 'limit' for the number of iterations, and 'filetype', which overrides the default filetype.

A figure is opened, and a pop-up box asks for the image scale. If using a FEI Helios 600 Nanolab Dual Beam system, you just have to type in the scale bar value. Otherwise, you can type "man" (for manual) and manually define a micron/px scale. If you've previously adapted the code, you can make shortcuts for calibrated objectives. Once the scale is set, select the usable region of interest (ROI) on the image and double click to accept. It is helpful to use as large a region as possible. A new figure is displayed with the cropped region. To make counting more managable, you can now choose a box size inside the ROI. Draw a box size that covers a reasonable number of grain boundaries to count per iteration, and double click to accept the box size. A new figure is displayed with a cropped section of the ROI and also with a dialog box asking for the number of intersected grain boundaries. Add the number and push enter or the OK button. The value is added to the history. The more iterations you perform, the more accurate your value should be. A zoom feature exists to help identify difficult-to-see grain boundaries. When asked for a number, type "zoom". To stop the zoom feature, type "zoom" again. Once the iterations stop, the data is saved in the image source folder.

Have fun counting!
