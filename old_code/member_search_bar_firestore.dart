import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RealTimeSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String collectionName; // Firestore collection to query
  final Function(String selectedItem)? onItemSelected; // Callback for item selection
  final String title; // Default title when not searching

  const RealTimeSearchAppBar({
    Key? key,
    required this.collectionName,
    this.onItemSelected,
    this.title = "Real-Time Search",
  }) : super(key: key);

  @override
  _RealTimeSearchAppBarState createState() => _RealTimeSearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _RealTimeSearchAppBarState extends State<RealTimeSearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  Stream<QuerySnapshot> _queryMembers(String prefix) {
    if (prefix.isEmpty) return Stream.empty();

    String endPrefix = prefix + '\uf8ff';

    return FirebaseFirestore.instance
        .collection(widget.collectionName)
        .where('name', isGreaterThanOrEqualTo: prefix)
        .where('name', isLessThanOrEqualTo: endPrefix)
        .snapshots();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: "Search members...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            )
          : Text(widget.title, style: const TextStyle(color: Colors.black)),
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _stopSearch,
            )
          : null,
      actions: !_isSearching
          ? [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: _startSearch,
              ),
            ]
          : null,
    );
  }

  Widget buildSearchOverlay() {
    return _isSearching
        ? Positioned.fill(
            child: GestureDetector(
              onTap: _stopSearch,
              child: Container(
                color: Colors.black54,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _queryMembers(_searchQuery),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No results found.",
                            style: TextStyle(color: Colors.white)),
                      );
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['name'] ?? 'No Name',
                              style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            if (widget.onItemSelected != null) {
                              widget.onItemSelected!(data['name']);
                            }
                            _stopSearch();
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          )
        : Container();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
