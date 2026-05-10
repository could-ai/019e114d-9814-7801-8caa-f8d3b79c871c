import 'dart:math';
import 'package:flutter/material.dart';
import 'models/city.dart';
import 'models/graph.dart';
import 'algorithms/tsp.dart';

void main() {
  runApp(const TSPApp());
}

class TSPApp extends StatelessWidget {
  const TSPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TSP Optimizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TSPHome(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class TSPHome extends StatefulWidget {
  const TSPHome({super.key});

  @override
  State<TSPHome> createState() => _TSPHomeState();
}

class _TSPHomeState extends State<TSPHome> {
  List<City> _cities = [];
  Graph? _graph;
  TspResult? _result;
  
  bool _useDynamicGraph = false;
  int _nodeCount = 5;
  String _selectedAlgorithm = 'Brute Force';
  
  final List<String> _algorithms = ['Brute Force', 'Greedy', '2-Opt (Custom)'];

  @override
  void initState() {
    super.initState();
    _generateRandomGraph();
  }

  void _generateRandomGraph() {
    final random = Random();
    _cities = List.generate(
      _nodeCount,
      (index) => City(
        id: index.toString(),
        name: 'City $index',
        x: random.nextDouble() * 300 + 20, // Keep within canvas bounds
        y: random.nextDouble() * 300 + 20,
      ),
    );
    
    _buildGraph();
  }

  void _buildGraph() {
    if (_useDynamicGraph) {
      _graph = DynamicGraph(_cities);
    } else {
      _graph = StaticGraph(_cities);
    }
    setState(() {
      _result = null; // Clear previous result
    });
  }

  void _runAlgorithm() {
    if (_cities.isEmpty) return;
    if (_cities.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Single city edge case: Cost is 0')),
      );
      setState(() {
        _result = TspResult(
          path: [_cities.first, _cities.first],
          cost: 0,
          executionTimeMs: 0,
          algorithmName: 'Edge Case',
        );
      });
      return;
    }

    setState(() {
      if (_selectedAlgorithm == 'Brute Force') {
        if (_cities.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Brute Force is too slow for >10 cities. Running anyway...')),
          );
        }
        _result = TspSolver.bruteForce(_graph!);
      } else if (_selectedAlgorithm == 'Greedy') {
        _result = TspSolver.greedy(_graph!);
      } else if (_selectedAlgorithm == '2-Opt (Custom)') {
        _result = TspSolver.twoOpt(_graph!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Optimization (TSP)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;
          
          Widget controls = _buildControls();
          Widget visualization = _buildVisualization();
          Widget metrics = _buildMetrics();

          if (isMobile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  controls,
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: visualization,
                  ),
                  const SizedBox(height: 16),
                  metrics,
                ],
              ),
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        controls,
                        const SizedBox(height: 16),
                        metrics,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: visualization,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Graph Representation:'),
                Switch(
                  value: _useDynamicGraph,
                  onChanged: (val) {
                    setState(() {
                      _useDynamicGraph = val;
                      _buildGraph();
                    });
                  },
                ),
              ],
            ),
            Text(_useDynamicGraph ? 'Dynamic (Adjacency List)' : 'Static (Adjacency Matrix)', 
                 style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Number of Cities:'),
            Slider(
              value: _nodeCount.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: _nodeCount.toString(),
              onChanged: (val) {
                setState(() {
                  _nodeCount = val.toInt();
                });
              },
              onChangeEnd: (val) {
                _generateRandomGraph();
              },
            ),
            ElevatedButton(
              onPressed: _generateRandomGraph,
              child: const Text('Generate Random Graph'),
            ),
            const SizedBox(height: 16),
            const Text('Algorithm:'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedAlgorithm,
              items: _algorithms.map((algo) => DropdownMenuItem(
                value: algo,
                child: Text(algo),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAlgorithm = val!;
                });
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _runAlgorithm,
              child: const Text('Run Algorithm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    if (_result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Run an algorithm to see metrics.'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              title: const Text('Algorithm'),
              trailing: Text(_result!.algorithmName),
            ),
            ListTile(
              title: const Text('Execution Time'),
              trailing: Text('${_result!.executionTimeMs.toStringAsFixed(4)} ms'),
            ),
            ListTile(
              title: const Text('Path Cost (Distance)'),
              trailing: Text(_result!.cost.toStringAsFixed(2)),
            ),
            ListTile(
              title: const Text('Memory/Representation'),
              trailing: Text(_useDynamicGraph ? 'Dynamic' : 'Static'),
            ),
            const Divider(),
            const Text('Optimal Route:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_result!.path.map((c) => c.name).join(' → ')),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualization() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: GraphPainter(
            cities: _cities,
            route: _result?.path,
          ),
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<City> cities;
  final List<City>? route;

  GraphPainter({required this.cities, this.route});

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final edgePaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw all possible edges
    for (int i = 0; i < cities.length; i++) {
      for (int j = i + 1; j < cities.length; j++) {
        canvas.drawLine(
          Offset(cities[i].x, cities[i].y),
          Offset(cities[j].x, cities[j].y),
          edgePaint,
        );
      }
    }

    // Draw optimal route
    if (route != null && route!.isNotEmpty) {
      for (int i = 0; i < route!.length - 1; i++) {
        canvas.drawLine(
          Offset(route![i].x, route![i].y),
          Offset(route![i+1].x, route![i+1].y),
          routePaint,
        );
      }
    }

    // Draw cities
    for (var city in cities) {
      canvas.drawCircle(Offset(city.x, city.y), 6, pointPaint);
      
      final textSpan = TextSpan(
        text: city.name,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(city.x + 8, city.y + 8));
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true; // Simplified for this demo
  }
}
