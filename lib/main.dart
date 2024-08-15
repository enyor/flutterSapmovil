import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/DatabaseHelper.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  // end

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProcedureScreen(),
    );
  }
}

class ProcedureScreen extends StatefulWidget {
  const ProcedureScreen({super.key});

  @override
  _ProcedureScreenState createState() => _ProcedureScreenState();
}

//Modelo de la tabla
class Item {
  final int? id;
  final String name;

  Item({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class _ProcedureScreenState extends State<ProcedureScreen> {
  String message = 'Hello World!';
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // Insertar registros
  Future<int> insertItem(Item item) async {
    Database db = await DatabaseHelper().database;
    return await db.insert('items', item.toMap());
  }

//Consultar Registros
  Future<List<Item>> getItems() async {
    Database db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('items');

    return List.generate(maps.length, (i) {
      return Item(
        id: maps[i]['id'],
        name: maps[i]['name'],
      );
    });
  }

// Agrega 1 registro
  Future<void> _addItem(String name) async {
    final item = Item(name: name);
    await insertItem(item);
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await getItems();
    setState(() {
      _items = items;
    });
  }

  Future<void> _executeProcedure(String proc) async {
    String endpoint = 'http://127.0.0.1:8000/api/execute-procedure';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'procedure_name': proc}),
    );
    if (response.statusCode == 200) {
      setState(() {
        message = 'Executed Procedure';
      });
    } else {
      setState(() {
        message = 'Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procedure Executor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _executeProcedure('control_conexion_sap'),
              child: const Text('Execute Procedure'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_items[index].name),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onSubmitted: (text) {
                  _addItem(text);
                },
                decoration: InputDecoration(
                  labelText: 'Enter item name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
