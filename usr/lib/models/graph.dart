import 'dart:math';
import 'city.dart';

abstract class Graph {
  List<City> cities;
  Graph(this.cities);

  double getDistance(int i, int j);
  void build();
}

class StaticGraph extends Graph {
  late List<List<double>> matrix;

  StaticGraph(super.cities) {
    build();
  }

  @override
  void build() {
    int n = cities.length;
    matrix = List.generate(n, (i) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i == j) {
          matrix[i][j] = 0.0;
        } else {
          double dx = cities[i].x - cities[j].x;
          double dy = cities[i].y - cities[j].y;
          matrix[i][j] = sqrt(dx * dx + dy * dy);
        }
      }
    }
  }

  @override
  double getDistance(int i, int j) => matrix[i][j];
}

class Edge {
  final int to;
  final double weight;
  Edge(this.to, this.weight);
}

class DynamicGraph extends Graph {
  late List<List<Edge>> adjList;

  DynamicGraph(super.cities) {
    build();
  }

  @override
  void build() {
    int n = cities.length;
    adjList = List.generate(n, (i) => []);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i != j) {
          double dx = cities[i].x - cities[j].x;
          double dy = cities[i].y - cities[j].y;
          double dist = sqrt(dx * dx + dy * dy);
          adjList[i].add(Edge(j, dist));
        }
      }
    }
  }

  @override
  double getDistance(int i, int j) {
    for (var edge in adjList[i]) {
      if (edge.to == j) return edge.weight;
    }
    return double.infinity;
  }
}
