/**
 * @file kdtree.cpp
 * Implementation of KDTree class.
 */

#include <utility>
#include <algorithm>

using namespace std;

template <int Dim>
bool KDTree<Dim>::smallerDimVal(const Point<Dim>& first,
                                const Point<Dim>& second, int curDim) const
{
    if (first[curDim] == second[curDim]) {
      return first < second; //tie
    } else {
      return (first[curDim] < second[curDim]);
    }
}

template <int Dim>
bool KDTree<Dim>::shouldReplace(const Point<Dim>& target,
                                const Point<Dim>& currentBest,
                                const Point<Dim>& potential) const
{
    double current_distance = 0.0;
    double potential_distance = 0.0;
    for (int i = 0; i < Dim; i++) {
      current_distance += (currentBest[i] - target[i]) * (currentBest[i] - target[i]);
      potential_distance += (potential[i] - target[i]) * (potential[i] - target[i]);
    }
    if (current_distance == potential_distance) {
      return potential < currentBest;
    } else {
      return potential_distance < current_distance;
    }
}

template <int Dim>
KDTree<Dim>::KDTree(const vector<Point<Dim>>& newPoints)
{
    if (newPoints.empty()) {
      size = 0;
      root = NULL;
    } else {
      size = 0;
      vector<Point<Dim>> p = newPoints;
      construct(p, 0, p.size() - 1, 0, root);
    }
}

/**
* helper function correspond to step 3
* @param newPoints points to select for node
* @param left left bound index
* @param right right bound index
* @param dim  dimention
* @param node nodes to be built
*/
template <int Dim>
void KDTree<Dim>::construct(vector<Point<Dim>>& newPoints, int left, int right, int dim, KDTreeNode*& node) {
  if (left > right) {
    return;
  }
  int index = (left + right) / 2;
  Point<Dim> p = quick_select(newPoints, left, right, index, dim);
  size += 1;
  node = new KDTreeNode(p);
  construct(newPoints, left, index - 1, (dim + 1) % Dim, node->left);
  construct(newPoints, index + 1, right, (dim + 1) % Dim, node->right);  //step 3 recursive call
}
/**
* quick select the point
* @param newPoints points to select for node
* @param left left bound index
* @param right right bound index
* @param index the index-th point to select
* @param dim  dimention
*/
template <int Dim>
Point<Dim> KDTree<Dim>::quick_select(vector<Point<Dim>>& newPoints, int left, int right, int index, int dim) {
  if (left == right) {
    return newPoints[left];
  }
  int partition_index = partition(newPoints, left, right, index, dim);
  if (index == partition_index) {
    return newPoints[index];
  } else if (index < partition_index) {
    return quick_select(newPoints, left, partition_index - 1, index, dim);
  } else {
    return quick_select(newPoints, partition_index + 1, right, index, dim);
  }
}
/**
* helper function for quick_select according to wiki
* @param newPoints points to select for node
* @param left left bound index
* @param right right bound index
* @param index the index-th point to select
* @param dim  dimention
*/

template <int Dim>
int KDTree<Dim>::partition(vector<Point<Dim>>& newPoints, int left, int right, int pivot_index, int dim) {
  Point<Dim> pivotValue = newPoints[pivot_index];
  swap(newPoints[pivot_index], newPoints[right]);  
  size_t storeIndex = left;
  for(int i = left; i < right; i++){
    if(smallerDimVal(newPoints[i], pivotValue, dim)){
      swap(newPoints[storeIndex], newPoints[i]);
      storeIndex++;
    }
  }
  swap(newPoints[right], newPoints[storeIndex]); 
  return storeIndex;
}

template <int Dim>
KDTree<Dim>::KDTree(const KDTree<Dim>& other) {
  copy_(root, other->root);
}

template <int Dim>
const KDTree<Dim>& KDTree<Dim>::operator=(const KDTree<Dim>& rhs) {

  delete_(root);
  copy_(root, rhs->root);
  return *this;
}

template <int Dim>
KDTree<Dim>::~KDTree() {

  delete_(root);
}

template <int Dim>
void KDTree<Dim>::copy_(KDTreeNode*& current, KDTreeNode*& other) {
  if (other == NULL) {
    return;
  }
  current = new KDTreeNode(other->point);
  copy_(current->left, other->left);
  copy_(current->right, other->right);
}

template <int Dim>
void KDTree<Dim>::delete_(KDTreeNode*& node) {
  if (node == NULL) {
    return;
  }
  delete_(node->left);
  delete_(node->right);
  delete node;
}

template <int Dim>
Point<Dim> KDTree<Dim>::findNearestNeighbor(const Point<Dim>& query) const
{

    Point<Dim> current = root->point;
    Point<Dim> target = query;
    help_find(current, target, root, 0);
    return current;
}

template <int Dim>
void KDTree<Dim>::help_find(Point<Dim> &currentBest, Point<Dim> &query, KDTreeNode* currentNode, int dim) const {
  if (currentNode == NULL) {
    return;
  }
  KDTreeNode* prior;
  KDTreeNode* later;
  if (smallerDimVal(query, currentNode->point, dim)) {
    prior = currentNode->left;
    later = currentNode->right;
  } else {
    prior = currentNode->right;
    later = currentNode->left;
  }
  help_find(currentBest, query, prior, (dim + 1) % Dim);
  //compare leaf, and then parent
  if (shouldReplace(query, currentBest, currentNode->point)) {
    currentBest = currentNode->point;
  }
  double r1 = 0.0;
  double r2 = 0.0;
  for(int i = 0; i < Dim; i++){
    r1 += (currentBest[i] - query[i]) * (currentBest[i] - query[i]);
  }
  r2 = (currentNode->point[dim] - query[dim]) * (currentNode->point[dim] - query[dim]);
  if (r1 >= r2) { //possibly exist in other plane
    help_find(currentBest, query, later, (dim + 1) % Dim);
  }
}