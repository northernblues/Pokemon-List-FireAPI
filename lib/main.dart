import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PokemonScreen(),
    );
  }
}

class PokemonScreen extends StatefulWidget {
  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  late Future<List<Map<String, dynamic>>> _pokemonListData;
  List<Map<String, dynamic>> _filteredPokemons = [];

  @override
  void initState() {
    super.initState();
    _pokemonListData = fetchPokemonListData();
  }

  Future<List<Map<String, dynamic>>> fetchPokemonListData() async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> pokemons = data['results'];
      return pokemons.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load Pokémon data');
    }
  }

  Future<Map<String, dynamic>> fetchPokemonDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load Pokémon details');
    }
  }

  void _filterPokemons(String keyword) async {
    List<Map<String, dynamic>> pokemons = await _pokemonListData;
    setState(() {
      _filteredPokemons = pokemons
          .where((pokemon) => pokemon['name'].toString().contains(keyword.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokemon List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterPokemons,
              decoration: InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _filteredPokemons.isEmpty ? _pokemonListData : Future.value(_filteredPokemons),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final List<Map<String, dynamic>> pokemons = snapshot.data!;

                  final List<Map<String, dynamic>> filteredPokemons = _filteredPokemons.isNotEmpty
                      ? _filteredPokemons
                      : [];

                  if (filteredPokemons.isEmpty) {
                    return Center(child: Text('No matching Pokémon found.'));
                  }

                  return ListView.builder(
                    itemCount: filteredPokemons.length,
                    itemBuilder: (context, index) {
                      final pokemon = filteredPokemons[index];
                      final String name = pokemon['name'];
                      final String url = pokemon['url'];

                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                            NetworkImage('https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${index + 1}.png'),
                          ),
                          title: Text(name),
                          subtitle: FutureBuilder<Map<String, dynamic>>(
                            future: fetchPokemonDetails(url),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Text('Loading...');
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                final List<dynamic> types = snapshot.data!['types'];
                                final String typeNames =
                                types.map((type) => type['type']['name']).join(', ');
                                return Text('Types: $typeNames');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
