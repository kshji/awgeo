# AwGeo - geo- and mappingtools
I am a skilled orienteer who works with maps using Ocad software.
In Finland, we are happy  because we have so much open source 
[geospatial data](https://asiointi.maanmittauslaitos.fi/karttapaikka/tiedostopalvelu?lang=en).
[License CC 4.0](https://creativecommons.org/licenses/by/4.0/deed.fi), 
data open source [National Land Survey of Finland](https://www.maanmittauslaitos.fi/en)

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
  * [Karttapullautin archive](https://www.routegadget.net/karttapullautin/), toolbox/workflow for generating O training maps from Lidar materials. Thank you Jarkko Ryyppö.
  * [Karttapullautin Github](https://github.com/rphlo/karttapullautin), same ***pullautin*** software, but rewrited using Rust - use this fast pullautin
  * [Karttapullautin Perl](https://github.com/linville/kartta-pack), org perl version, still updated - some options has only in this version
  * [LasPy](https://laspy.readthedocs.io/), [Python library](https://pypi.org/project/laspy/) for lidar LAS/LAZ IO, [Github](https://github.com/laspy/laspy)
  * [OCAD](https://ocad.com), Cad for mapping
  * [Omapper](https://www.openorienteering.org/apps/mapper/), OMapper open source for mapping
  * [PurplePen](https://purple-pen.org), free course setting software for orienteering

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
#sudo apt-get install proj-bin libproj-dev
sudo apt-get install python3-dev python3.8-dev python3-pip
# update PIP
pip3 install --upgrade pip

# GDAL install include PROJ
# Official stable UbuntuGIS packages.
sudo add-apt-repository ppa:ubuntugis/ppa
sudo apt-get update
sudo apt-get install gdal-bin libgdal-dev 
#       Check:
ogrinfo --version

sudo apt-get install python3-gdal python3-numpy

# If using perl and need GDAL, then
sudo apt-get install libgd-gd2-perl
# PDAL
sudo apt-get install -y pdal libpdal-plugins
```

If you get error ***free(): invalid pointer*** using cmds:
```sh
ogrinfo --version
gdalinfo --version
pdal --version
```
Then you have problem with libproj versions.
Solutions is usually to find correct libproj = latest and then soft link to the older version numbers.

[Read solutions](https://stackoverflow.com/questions/72345761/gdal-ogr2ogr-ogrinfo-produces-an-invalid-pointer-error-each-time-i-run-it).


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


## Awot sh-scripts use various software, including proj, gdal, pdal, lastools, ...
All example files are in the ***examples*** directory.

### setup AWGEO env
After you have get copy of ***awgeo***, you need setup ***config/awgeo.ini*** file.
Example if this directory is /home/user/awgeo then your configfile 
/home/user/awgeo/config/awgeo.ini
has one line:
```
AWGEO=/home/user/awgeo
```


### raw2xy.sh - Make XY polygon file from Ocad polygon information
 * draw polygon in Ocad
 * get polygon info (button i)
 * copy polycon text to the textfile ex. area.raw

Convert raw to the xy format:
```sh
../raw2xy.sh -i area.raw -o area.txt

```

### xy2wkt.sh - Make WKT Polygon from x,y polygon text file

Convert x,y polygon textfile to the WKT polygon format.

```sh
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
hillshade.sh -i input.laz -o resultname [ -z NUMBER ] [ -g 0|1 ] [ -d 0|1 ]
   -i input laz file name
   -o resultname, result file is resultname.tif !!!
   -g 0|1 , default 1, using ground filter or not
   -z NUMBER  , default is 3
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

### Rotate GeoTIFF
[Source](https://gis.stackexchange.com/questions/418517/rotation-of-a-spatial-grid-by-an-angle-around-a-pivot-with-python-gdal-or-raster) for this solution. 
Thanks for [WaterFox](https://gis.stackexchange.com/users/167793/waterfox).

```sh
python3 rotate.angle.py source.tif  angle rotated.tif
# angle is +/- degrees
```

### Remove geogoords from GeoTiff
Need to remove geodata from GeoTiff => it is "only" tif image without geolocation.

```sh
gdal_translate -of GTiff -co PROFILE=BASELINE input.tif output.tif
# or
cp geotif.tif output.tif
gdal_edit.py  -unsetgt output.tif
```


### Forest "hillshade" from LAZ

More documentation in the script.
```sh
forest.sh
```

### Hillshade and Forest "hillshade" from LAZ

Do both hillshade.sh and forest.sh

More documentation in the script.
```sh
forest_hillshade.sh
```

### Karttapullautin batch execute

pullauta.run.sh is my version to batch ***pullauta*** process.

#### setup
 * mkdir input and output
 * config/pullauta.ini use some variable = dynamic template , make your edits to this version
 * edit awgeo.ini, set directory where is AwGeo binary's

#### config/pullauta.ini
Have to set:
```sh
batch=1
processes=4  # how many core you can use 
batchoutfolder=./output
lazfolder=./input
```

#### execute

Normal batch:
 * put input files to the dir input: LAZ + Maastotietokanta SHP zipped (ZIP)
 * execute pullauta
 * make also hillshade and intermediate curves

```sh
pullauta.run.sh -a 11 -i 0.625 -s -z 3
# - northlineangle 11, intermediate curve 0.625, hillshade using z=3
```

Only map without hillshade and intermediate curves, nothlines angle 11: If angle=0, no northlines.
```sh
pullauta.run.sh -a 11 
```

Re-run only using tempfiles hillshade:
 * reuse temp files
```sh
pullauta.run.sh --onlyhillshade  -s  -z 3
```

Re-run only using tempfiles intermediate curves:
```sh
pullauta.run.sh --onlyintermediate -i 0.625
# - run only intermediate curves (0.625 m) after basic run - use temp files
```

