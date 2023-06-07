import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  // List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'flutter-app-b6607-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery data. Please try again later.');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((element) => element.value.name == item.value['category'])
          .value;

      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }

    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _loadedItems = _loadItems();
    });
  }

  void _removeItem(GroceryItem item) async {
    final url = Uri.https(
      'flutter-app-b6607-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    await http.delete(url);

    setState(() {
      _loadedItems = _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle),
            )
          ],
        ),
        body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                ),
              );
            }

            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('No items added yet.'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: ((ctx, index) => Dismissible(
                    onDismissed: (direction) {
                      _removeItem(snapshot.data![index]);
                    },
                    background: Container(
                      color: Theme.of(context).colorScheme.onError,
                    ),
                    key: ValueKey(snapshot.data![index].id),
                    child: ListTile(
                      title: Text(snapshot.data![index].name),
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          color: snapshot.data![index].category.color,
                        ),
                      ),
                      trailing: Text(
                        snapshot.data![index].quantity.toString(),
                      ),
                      // tileColor: Colors.black26,
                    ),
                  )),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            );
          },
        ));
  }
}
