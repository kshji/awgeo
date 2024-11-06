# AwGeo - geo- and mappingtools
I am a skilled orienteer who works with maps using Ocad software.
In Finland, we are happy  because we have so much open source 
[geospatial data](https://asiointi.maanmittauslaitos.fi/karttapaikka/tiedostopalvelu?lang=en).

  * [Awot](https://awot.fi), my company
  * [Suunnistus.info](https://suunnistus.info), my orienteering pages
  * [Kalevan Rasti](https://kalevanrasti.fi), my orienteering club
  * [Github kshji](https://github.com/kshji), my github

## The tools used to find the needs for processing geodata
My geo programs use various software, including Lastools, PDAL and GDAL.
    
  * [PROJ](https://proj.org/)
  * [GDAL](https://gdal.org/)
  * [PDAL](https://pdal.io/)
  * [Lastools](https://lastools.github.io/)
  * [Karttapullautin](https://www.routegadget.net/karttapullautin/), toolbox/workflow for generating O training maps from Lidar materials. Thank you Jarkko Ryyppö.
  * [LasPy](https://laspy.readthedocs.io/), [Python library](https://pypi.org/project/laspy/) for lidar LAS/LAZ IO, [Github](https://github.com/laspy/laspy)
  * [OCAD](https://ocad.com), Cad for mapping

The full licence terms can be found on the individual pages of the following tools.

### My online tools
  * [Shp2Dxf](https://awot.fi/sf/ocad/shp2dxf) my online tool to make DXF from Shapefiles, ex. using in the [Ocad](https://ocad.com)
  * [Ocad angle correction GD: declination + convergence](https://awot.fi/sf/ocad/ocaddec?lang=eng)

### Lidar maps and tools
  * [GeoTIFF.io](https://app.geotiff.io/) GeoTiff viewer, 
  * [Pullautuskartta](https://pullautuskartta.fi/)
  * [MapAnt FI](https://mapant.fi/)
  * [CloudCompare](https://github.com/cloudcompare/cloudcompare), CloudCompare is a 3D point cloud processing software. Also light CcViewer.
  * [QGIS](https://www.qgis.org/), Spatial visualization and decision-making tools for everyone - Open Source
  * [Courses: Point cloud processing with QGIS and PDAL wrench](https://courses.gisopencourseware.org/course/view.php?id=63)
  * [Courses: Programming for Geospatial Hydrological Applications](https://courses.gisopencourseware.org/course/view.php?id=2)
  * [Geospatial School](https://geospatialschool.com/)
  * [Awesome-Geospatial](https://github.com/sacridini/Awesome-Geospatial), list of geotools
  * [Proj Widard](https://projectionwizard.org/)

### Other interesting tools
  * [Virtual DOS](https://copy.sh/v86/?profile=msdos), [Github](https://github.com/copy/v86), also Linux, Windows98, ... nice.

### Install tools
This example is for Ubuntu, Debian, WSL2 Ubuntu, ... 

Each software pages include also download for Windows, OS/X, ...

#### Ubuntu, Debian, WSL2 Ubuntu, ...

```sh
sudo apt-get install proj-bin libproj-dev
sudo apt-get install python3-dev python3.8-dev python3-pip
# update PIP
pip3 install --upgrade pip

# GDAL
# Official stable UbuntuGIS packages.
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
sudo apt-get install gdal-bin libgdal-dev
#       Check:
ogrinfo --version

sudo apt-get install python3-gdal
sudo apt-get install python3-numpy

# If using perl and need GDAL, then
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


## My sh-scripts use various software, including proj, gdal, pdal, lastools, ...
All example files are in the ***examples*** directory.

### xy2wkt.sh - Make WKT Polygon from x,y polygon text file

Convert x,y polygon textfile to the WKT polygon format.

```
cd examples
cat area.txt
632162.5 6954655.8
632176.7 6954656.9
632200.1 6954651.5
632162.5 6954655.8

../xy2wkt.sh -i area.txt -o area.wkt
# or using pipe
cat area.txt | ../xy2wkt.sh > area.wkt
```

### lazcrop.sh - Crop polygon area from LAZ file
You can use Lastools ***lasclip*** or this small PDAL script to crop polygon area from laz file.
lazcrop.sh need polygon in WKT Polygon format. Look ***xy2wkt.sh*** how to convert x,y textfile to the wkt format.

```sh
# using lastools
lasclip64 -i example.laz -o areax.las -poly area.txt
# using lazcrop.sh
../lazcrop.sh -i example.laz -p area.wkt -o areay.las

```

### laz2tif.sh - Make GeoTiff from LAZ file
```sh
laz2tif.sh -i input.laz -o result.tif [ -d 0|1 ]
   -i input laz file name
   -o result tif file
   -d 0|1 , default 0 - debug output
   -v       version
   -h       this help
```
Example from example.laz
```sh
cd examples
../laz2tif.sh -i example.laz -o example1.tif
```
Result file is example1.tif

### hillshade.sh - Make hillshade from lidar file (laz)

<img src="../../blob/master/examples/example1.png" width="30%" height="30%">

```sh
hillshade.sh -i input.laz -o resultname [ -g 0|1 ] [ -d 0|1 ]
   -i input laz file name
   -o resultname, result file is resultname.tif !!!
   -g 0|1 , default 1, using ground filter or not
   -d 0|1 , default 0 - debug output
   -v 	     version
   -h       this help
```
Example hillshade from example.laz
```sh
cd examples
../hillshade.sh -i example.laz -o example1
```
Result file is example1.tif

Convert Tiff to PNG
```sh
gdal_translate -of PNG example1.tif example1.png
```

  * default values, look hillshade.sh, funtion *json and set_def.

### lidar_volume.py - Calculate volume of Lidar

<img src="../../blob/master/examples/hill.png" width="30%" height="30%">
Example hill, calculate volume.

Calculate the volume from the Lidar data (LAZ-file) data above a certain height.

***lidar_volume.py*** I have used to calculate volume of lidar, using some base z-index.

Here is example how to clip some area from LAZ-file and then calculate volume above level 112.
```sh
cd examples
# unzip laz and clip area using polycon area.txt
lasclip64 -i example.laz -o areax.las -poly area.txt  -keep_class 2
# or drop below 112 data already in this step, lidar_volume.py also accept above level value
lasclip64 -i example.laz -o areax.las -poly area.txt  -keep_class 2  -drop_z_below 112
# or using my lazcrop.sh

# or using Pdal to unzip laz to las
pdal translate example.laz example.las

# look lazcrop.sh how to clip polygon from the LAZ-file

# calculate volume 
python3 ../lidar_volume.py areax.las 112
112.0 38780.31 m3

```


