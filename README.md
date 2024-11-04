# AwGeo Geo- and mappingtools


## The tools used to find solution for my geoneeds ###
    
   * [PROJ](https://proj.org/)
   * [GDAL](https://gdal.org/)
   * [PDAL](https://pdal.io/)
   * [Lastools](https://lastools.github.io/)
   * [Karttapullautin](https://www.routegadget.net/karttapullautin/), toolbox/workflow for generating O training maps from Lidar materials
   * [LasPy](https://laspy.readthedocs.io/), [Python library](https://pypi.org/project/laspy/) for lidar LAS/LAZ IO, [Github](https://github.com/laspy/laspy)

The full licence terms can be found on the individual pages of the following tools.

### My online tools
   * [Shp2Dxf](https://awot.fi/sf/ocad/shp2dxf) my online tool to make DXF from Shapefiles, ex. using in [Ocad](https://ocad.com)
   * [Ocad angle correction GD: declination + convergence](https://awot.fi/sf/ocad/ocaddec?lang=eng)

### Lidar maps and tools
   * [Pullautuskartta](https://pullautuskartta.fi/)
   * [MapAnt FI](https://mapant.fi/)
   * [CloudCompare](https://github.com/cloudcompare/cloudcompare), CloudCompare is a 3D point cloud processing software. Also light CcViewer.

### Install tools
This example is for Ubuntu, Debian, WSL2 Ubuntu, ... 

Each software pages include also download for Windows and so on.

#### Ubuntu, Debian, WSL2 Ubuntu, ...

```sh
sudo apt-get install proj-bin libproj-dev
sudo apt-get install python3-dev python3.8-dev

# GDAL
# Official stable UbuntuGIS packages.
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
apt-get install gdal-bin libgdal-dev
#       Check:
ogrinfo --version

       sudo apt-get install python3-gdal
# If using perl, then
       sudo apt-get install libgd-gd2-perl
# PDAL
       sudo apt-get install pdal
```

#### Pip for python
```sh
# User env
#       - look version using: ogrinfo --version
#       - in this example version is 3.3.2
       pip install GDAL==3.3.2
       pip install pygdal=="3.3.2.*"
       pip install laspy[laszip]
       pip install scipy numpy
       pip install lasio


```


## My script to use proj, gdal, pdal, lastools, ...

### hillshade.sh - Make hillshade from lidar file (laz)

```sh
hillshade.sh -i input.laz -o resultname [ -g 0|1 ] [ -d 0|1 ]
  * -i input laz file name
  * -o resultname, result file is resultname.tif !!!
  * -g 0|1 , default 1, using ground fileter or not
  * -d 0|1 , default 0 - debug output
  * -v 	     version
  * -h       this help
  
```

### lidar_volume.py - Calculate volume of Lidar

***lidar_volume.py*** I have used to calculate volume of lidar, using some base z-index.

Here is example how to clip some area from LAZ-file and then calculate volume above level 112
```
# unzip laz and clip area using polycon area.txt
lasclip64 -i P5313E1.laz -o areax.las -poly area.txt  -keep_class 2
# or drop below 112 data already in this step, lidar_volume.py also accept above level value
lasclip64 -i P5313E1.laz -o areax.las -poly area.txt  -keep_class 2  -drop_z_below 112

# or using Pdal to unzip laz to las
pdal translate P5313E1.laz P5313E1.las

# clip is not so easy with Pdal as using Lastools

# calculate volume 
python3 lidar_volume.py areax.las 112
The volume above height 112.0 is: 226715.38 cubic meters

