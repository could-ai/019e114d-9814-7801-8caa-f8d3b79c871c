import '../models/graph.dart';

class TSPResult {
  final List<int> path;
  final double cost;
  final Duration executionTime;

  TSPResult(this.path, this.cost, this.executionTime);
}

abstract class TSPAlgorithm {
  TSPResult solve(Graph graph);
}

class BruteForceTSP extends TSPAlgorithm {
  @override
  TSPResult solve(Graph graph) {
    final stopwatch = Stopwatch()..start();
    int n = graph.cities.length;
    List<int> bestPath = [];
    double bestCost = double.infinity;

    void permute(List<int> arr, int k) {
      if (k == n) {
        double currentCost = 0;
        for (int i = 0; i < n - 1; i++) {
          currentCost += graph.getDistance(arr[i], arr[i + 1]);
        }
        currentCost += graph.getDistance(arr[n - 1], arr[0]);

        if (currentCost < bestCost) {
          bestCost = currentCost;
          bestPath = List.from(arr);
        }
        return;
      }
      for (int i = k; i < n; i++) {
        int temp = arr[i];
        arr[i] = arr[k];
        arr[k] = temp;
        permute(arr, k + 1);
        temp = arr[i];
        arr[i] = arr[k];
        arr[k] = temp;
      }
    }

    if (n == 0) return TSPResult([], 0, Duration.zero);
    if (n == 1) return TSPResult([0], 0, Duration.zero);

    List<int> initial = List.generate(n, (index) => index);
    permute(initial, 1); 
    bestPath.add(bestPath[0]); 

    stopwatch.stop();
    return TSPResult(bestPath, bestCost, stopwatch.elapsed);
  }
}

class GreedyTSP extends TSPAlgorithm {
  @override
  TSPResult solve(Graph graph) {
    final stopwatch = Stopwatch()..start();
    int n = graph.cities.length;
    if (n == 0) return TSPResult([], 0, Duration.zero);
    if (n == 1) return TSPResult([0], 0, Duration.zero);

    List<int> path = [0];
    Set<int> visited = {0};
    double cost = 0;

    int current = 0;
    while (visited.length < n) {
      int nextCity = -1;
      double minDistance = double.infinity;
      for (int j = 0; j < n; j++) {
        if (!visited.contains(j)) {
          double dist = graph.getDistance(current, j);
          if (dist < minDistance) {
            minDistance = dist;
            nextCity = j;
          }
        }
      }
      path.add(nextCity);
      visited.add(nextCity);
      cost += minDistance;
      current = nextCity;
    }
    cost += graph.getDistance(current, 0);
    path.add(0);

    stopwatch.stop();
    return TSPResult(path, cost, stopwatch.elapsed);
  }
}

class TwoOptTSP extends TSPAlgorithm {
  @override
  TSPResult solve(Graph graph) {
    final stopwatch = Stopwatch()..start();
    int n = graph.cities.length;
    if (n == 0) return TSPResult([], 0, Duration.zero);
    if (n == 1) return TSPResult([0], 0, Duration.zero);

    GreedyTSP greedy = GreedyTSP();
    TSPResult greedyResult = greedy.solve(graph);
    List<int> path = List.from(greedyResult.path)..removeLast(); 
    
    bool improved = true;
    while (improved) {
      improved = false;
      for (int i = 1; i < n - 1; i++) {
        for (int j = i + 1; j < n; j++) {
          double dist1 = graph.getDistance(path[i - 1], path[i]) + graph.getDistance(path[j], path[(j + 1) % n]);
          double dist2 = graph.getDistance(path[i - 1], path[j]) + graph.getDistance(path[i], path[(j + 1) % n]);
          if (dist2 < dist1) {
            path.replaceRange(i, j + 1, path.sublist(i, j + 1).reversed);
            improved = true;
          }
        }
      }
    }
    
    path.add(path[0]);
    double totalCost = 0;
    for (int i = 0; i < path.length - 1; i++) {
      totalCost += graph.getDistance(path[i], path[i + 1]);
    }

    stopwatch.stop();
    return TSPResult(path, totalCost, stopwatch.elapsed);
  }
}
