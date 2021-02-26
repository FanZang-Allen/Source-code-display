/**
 * @file kdtree.h
 * KDTree implementation using Points in k-dimensional space.
 *
 * @author Zesheng Wang
 * @author Wade Fagen-Ulmschneider
 * @author Cinda Heeren
 * @author Jack Toole
 * @author Sean Massung
 */

#pragma once

#include <vector>
#include "util/coloredout.h"
#include "point.h"

using std::vector;
using std::string;
using std::ostream;
using std::cout;
using std::endl;

/**
 * KDTree class: implemented using Points in Dim dimensional space (given
 * by the template parameter).
 */
template <int Dim>
class KDTree
{
  private:
    /**
     * Internal structure for a node of KDTree.
     * Contains left, right children pointers and a K-dimensional point
     */
    struct KDTreeNode
    {
      Point<Dim> point;
      KDTreeNode *left, *right;

      KDTreeNode() : point(), left(NULL), right(NULL) {}
      KDTreeNode(const Point<Dim> &point) : point(point), left(NULL), right(NULL) {}
    };

  public:
    /**
     * Determines if Point a is smaller than Point b in a given dimension d.
     * If there is a tie, break it with Point::operator<().
     *
     * @param first Point to compare.
     * @param second Second point to compare.
     * @param curDim Dimension these points are being compared in.
     * @return A boolean value indicating whether the first Point is smaller
     *  than the second Point in the curDim dimension.
     */
    bool smallerDimVal(const Point<Dim>& first, const Point<Dim>& second,
                       int curDim) const;

    /**
     * Determines if a Point is closer to the target Point than another
     * reference Point. Takes three points: target, currentBest, and
     * potential, and returns whether or not potential is closer to
     * target than currentBest.
     * @param target The Point we want to be close to.
     * @param currentBest The Point that is currently our closest Point
     *    to target.
     * @param potential Our Point that is a candidate to replace
     *    currentBest (that is, it may be closer to target than
     *    currentBest).
     * @return A boolean value indicating whether potential is closer
     *  to target than currentBest. Ties should be broken with
     *  Point::operator<().
     */
    bool shouldReplace(const Point<Dim>& target, const Point<Dim>& currentBest,
                       const Point<Dim>& potential) const;

    /**
     * Constructs a KDTree from a vector of Points, each having dimension Dim.
     * @param newPoints The vector of points to build your KDTree off of.
     */
    KDTree(const vector<Point<Dim>>& newPoints);


    /**
     * Copy constructor for KDTree.
     *
     * @param other The KDTree to copy.
     */
    KDTree(const KDTree<Dim>& other);

    /**
     * Assignment operator for KDTree.
     *
     * @param rhs The right hand side of the assignment statement.
     * @return A reference for performing chained assignments.
     */
    KDTree const &operator=(const KDTree<Dim>& rhs);

    /**
     * Destructor for KDTree.
     */
    ~KDTree();

    /**
     * Finds the closest point to the parameter point in the KDTree.
     *
     * @param query The point we wish to find the closest neighbor to in the
     *  tree.
     * @return The closest point to a in the KDTree.
     */
    Point<Dim> findNearestNeighbor(const Point<Dim>& query) const;

    // functions used for grading:

    /**
     * Prints the KDTree to the terminal in a pretty way.
     */
    void printTree(ostream& out = cout,
                   colored_out::enable_t enable_bold = colored_out::COUT,
                   int modWidth = -1) const;

  private:

    /** Internal representation, root and size **/
    KDTreeNode *root;
    size_t size;

    int getPrintData(KDTreeNode * subroot) const;

    void printTree(KDTreeNode * subroot, std::vector<std::string>& output,
                   int left, int top, int width, int currd) const;

    void construct(vector<Point<Dim>>& newPoints, int left, int right, int dim, KDTreeNode*& node);

    Point<Dim> quick_select(vector<Point<Dim>>& newPoints, int left, int right, int index, int dim);
    
    int partition(vector<Point<Dim>>& newPoints, int left, int right, int pivot_index, int dim);

    void copy_(KDTreeNode*& current, KDTreeNode*& other);

    void delete_(KDTreeNode*& node);

    void help_find(Point<Dim> &currentBest, Point<Dim> &query, KDTreeNode* currentNode, int dim) const;
};

#include "kdtree.hpp"
#include "kdtree_extras.hpp"