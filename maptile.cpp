/**
 * @file maptiles.cpp
 * Code for the maptiles function.
 */

#include <iostream>
#include <map>
#include "maptiles.h"
//#include "cs225/RGB_HSL.h"

using namespace std;


Point<3> convertToXYZ(LUVAPixel pixel) {
    return Point<3>( pixel.l, pixel.u, pixel.v );
}

MosaicCanvas* mapTiles(SourceImage const& theSource,
                       vector<TileImage>& theTiles)
{
    /**
     * @todo Implement this function!
     */

    MosaicCanvas* image = new MosaicCanvas(theSource.getRows(), theSource.getColumns());
    
    map<Point<3>, size_t> tiles_map;//using points as key to get suitable tileimage
    vector<Point<3>> kd_points; //all transformed points of tileimages

    for(size_t i = 0; i < theTiles.size(); i++){
      LUVAPixel pixel = theTiles[i].getAverageColor();
      Point<3> point = convertToXYZ(pixel);
      kd_points.push_back(point);
      tiles_map.insert(pair<Point<3>, size_t>(point,i));
    }

    KDTree<3>* kdtree = new KDTree<3>(kd_points);

    for(int i = 0; i < theSource.getRows(); i++){
      for(int j = 0; j < theSource.getColumns(); j++){
        LUVAPixel color = theSource.getRegionColor(i, j);
        Point<3> target_point = convertToXYZ(color);
        Point<3> nearest_point = kdtree->findNearestNeighbor(target_point);
        size_t index = tiles_map[nearest_point];
        image->setTile(i, j, &theTiles[index]);
      }
    }
    
    delete kdtree; 
    return image;
}