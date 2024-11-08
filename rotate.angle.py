# rotate.angle.py
# source idea from 
# https://gis.stackexchange.com/questions/418517/rotation-of-a-spatial-grid-by-an-angle-around-a-pivot-with-python-gdal-or-raster

import sys
from optparse import OptionParser
import rasterio
from affine import Affine  # For easly manipulation of affine matrix
from rasterio.warp import reproject, Resampling
import numpy as np

def get_center_pixel(dataset):
    """This function return the pixel coordinates of the raster center
    """
    width, height = dataset.width, dataset.height
    # We calculate the middle of raster
    x_pixel_med = width // 2
    y_pixel_med = height // 2
    return (x_pixel_med, y_pixel_med)

def rotate(inputRaster, angle, scale=1, outputRaster=None):
    outputRaster = 'rotated.tif' if outputRaster is None else outputRaster

    ### Read input
    source = rasterio.open(inputRaster)
    #assert source.crs == 'EPSG:4326', "Raster must have CRS=EPSG:4326, that is unprojected lon/lat (degree) relative to WGS84 datum"

    ### Rotate the affine about a pivot and rescale
    pivot = get_center_pixel(source)
    #pivot = None
    print("\nPivot coordinates:", source.transform * pivot)
    new_transform = source.transform * Affine.rotation(angle, pivot) * Affine.scale(scale)

    # this is a 3D numpy array, with dimensions [band, row, col]
    data = source.read(masked=True)
    kwargs = source.meta
    kwargs['transform'] = new_transform

    with rasterio.open(outputRaster, 'w', **kwargs) as dst:
        for i in range(1, source.count + 1):
            reproject(
                source=rasterio.band(source, i),
                destination=rasterio.band(dst, i),
                src_transform=source.transform,
                src_crs=source.crs,
                dst_transform=new_transform,
                dst_crs=dst.crs,
                resampling=Resampling.average)
    return

def main():
    if len(sys.argv) < 4:
       	prg = sys.argv[0]
       	print(f'Usage: python3 {prg} <filename> <angle> <outfile>')
       	sys.exit(1)
    return rotate(sys.argv[1],float(sys.argv[2]),1.0,sys.argv[3])
	
    

if __name__ == '__main__':
    import sys
    main()
