
import 'package:flutter/material.dart';
import 'package:painter/painter.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'dart:typed_data';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing Art',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Offset> points = <Offset>[];

  @override
  Widget build(BuildContext context) {
    final Container sketchArea = Container(
      margin: EdgeInsets.all(1.0),
      alignment: Alignment.topLeft,
      color: Colors.blueGrey[50],
      child: CustomPaint(
        painter: Sketcher(points),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing'),
      ),

      body: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            RenderBox box = context.findRenderObject();
            Offset point = box.globalToLocal(details.globalPosition);
            point = point.translate(0.0, -(AppBar().preferredSize.height));

            points = List.from(points)..add(point);
          });
        },
        onPanEnd: (DragEndDetails details) {
          points.add(null);
        },
        child: sketchArea,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'clear Screen',
        backgroundColor: Colors.red,
        child: MyFireStore(),
        onPressed: () {
          setState(() => points.clear());
        },
      ),
    );

  }
}

class MyFireStore extends StatefulWidget {
  @override
  _MyFireStoreState createState() => _MyFireStoreState();

}

class _MyFireStoreState extends State<MyFireStore>{
  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }
}

Widget _buildBody(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: Firestore.instance.collection('xVar').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return LinearProgressIndicator();

      return _buildList(context, snapshot.data.documents);
    },
  );
}

Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
  return ListView(
    //padding: const EdgeInsets.only(top: 20.0),
    children: snapshot.map((data) => _buildListItem(context, data)).toList(),
  );
}

Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
  final record = Record.fromSnapshot(data);

  return Padding(
    key: ValueKey(record.xVar),
    // key: ValueKey(record.yVar),
    //padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Container(
      //decoration: BoxDecoration(
      //border: Border.all(color: Colors.grey),
      //borderRadius: BorderRadius.circular(5.0),
      // ),
      child: ListTile(
        //title: Text(record.x.toString()),
        //trailing: Text(record.x.toString()),
        onTap: () => Firestore.instance.runTransaction((transaction) async {
          final freshSnapshot = await transaction.get(record.reference);
          final fresh = Record.fromSnapshot(freshSnapshot);

          await transaction
              .update(record.reference, {'xVar': fresh.xVar});
          //   .update(record.reference, {'yVar: fresh.yVar'});
        }),
      ),
    ),
  );
}


class Sketcher extends CustomPainter {
  final List<Offset> points;

  Sketcher(this.points);

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.points != points;
  }

  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);

        print(points[i]);
        print(points[i+1]);
      }
    }

  }
}

class Record {
  double xVar;
  // final double yVar;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['xVar'] != null),
  //   assert(map['yVar'] != null),
        xVar = map['xVar'];
  //   yVar = map['yVar'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

//@override
//String toString() => "Record<$point:$x>";
}

