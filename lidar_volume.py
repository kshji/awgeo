# python3 lidar_volume.py some.las 112
# calculate volume above the level 112 using some.las
import sys
import numpy as np
import laspy
from scipy.spatial import Delaunay

def load_lidar_data(file_path):
    with laspy.open(file_path) as f:
        point_cloud = f.read()
        x = point_cloud.x
        y = point_cloud.y
        z = point_cloud.z
    return x, y, z

def triangulate_points(x, y):
    points = np.vstack((x, y)).T
    tri = Delaunay(points)
    return tri

def calculate_volume(tri, z, height_threshold):
    volume = 0.0
    for simplex in tri.simplices:
        # Get the vertices of the triangle
        triangle_points = tri.points[simplex]
        triangle_z = z[simplex]
        
        # Calculate the area of the triangle
        area = 0.5 * np.abs(
            triangle_points[0][0] * (triangle_points[1][1] - triangle_points[2][1]) +
            triangle_points[1][0] * (triangle_points[2][1] - triangle_points[0][1]) +
            triangle_points[2][0] * (triangle_points[0][1] - triangle_points[1][1])
        )
        
        # Calculate the average height of the triangle
        avg_height = np.mean(triangle_z)
        
        # Calculate volume above the height threshold
        if avg_height > height_threshold:
            volume += area * (avg_height - height_threshold)
    
    return volume

def main():
    if len(sys.argv) != 3:
        prg = sys.argv[0]
        print(f'Usage: python3 {prg} <filename> <level>')
        sys.exit(1)

    #file_path = 'some.las'
    file_path = sys.argv[1]
    #height_threshold = 112  # Change this to your desired height
    height_threshold = float(sys.argv[2])

    x, y, z = load_lidar_data(file_path)
    tri = triangulate_points(x, y)
    volume = calculate_volume(tri, z, height_threshold)

    print(f'The volume above height {height_threshold} is: {volume:.2f} cubic meters')

if __name__ == "__main__":
    main()


