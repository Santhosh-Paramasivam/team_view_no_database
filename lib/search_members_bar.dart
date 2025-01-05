import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_view_no_database_windows/session_data/session_details.dart';

class MemberSearchBar extends StatefulWidget implements PreferredSizeWidget {
  final void Function(String) displayMemberNew;

  const MemberSearchBar(
    Key key,
    this.displayMemberNew,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<MemberSearchBar> createState() => MemberSearchBarState();
}

class MemberSearchBarState extends State<MemberSearchBar> {
  late List<String> searchTerms;
  late String appUserInstitutionID;
  late String searchBarLabel;

  @override
  initState() {
    searchTerms = [];
    appUserInstitutionID = SessionDetails.institution_id;
    searchBarLabel = "Search People";
  }

  void updateSearchBarLabel(String query) {
    setState(() {
      searchBarLabel = "Searched $query";
    });
  }

  Future<List<String>> fetchSearchSuggestions(String query) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("institution_members")
        .where("institution_id", isEqualTo: appUserInstitutionID)
        .where("name", isGreaterThanOrEqualTo: query)
        .where("name", isLessThanOrEqualTo: "$query\uf8ff")
        .limit(5)
        .get();

    return querySnapshot.docs.map((doc) => doc["name"] as String).toList();
  }

  @override
  AppBar build(BuildContext context) {
    return AppBar(
      title: Text(searchBarLabel),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        IconButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(
                fetchSearchSuggestions,
                widget.displayMemberNew,
                updateSearchBarLabel,
              ),
            );
          },
          icon: const Icon(Icons.search),
        )
      ],
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final Future<List<String>> Function(String) fetchSearchSuggestions;
  final void Function(String) displayMemberNew;
  final void Function(String) updateSearchBarLabel;

  CustomSearchDelegate(
    this.fetchSearchSuggestions,
    this.displayMemberNew,
    this.updateSearchBarLabel,
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchSearchSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error fetching data"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No results found"));
        }

        final matchQuery = snapshot.data!;
        return ListView.builder(
          itemCount: matchQuery.length,
          itemBuilder: (context, index) {
            final result = matchQuery[index];
            return ListTile(
              title: TextButton(
                onPressed: () {
                  query = result;
                  updateSearchBarLabel(query);
                  displayMemberNew(query);
                  close(context, null);
                },
                child: Text(result),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchSearchSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error fetching data"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No suggestions found"));
        }

        final matchQuery = snapshot.data!;
        return ListView.builder(
          itemCount: matchQuery.length,
          itemBuilder: (context, index) {
            final result = matchQuery[index];
            return ListTile(
              title: TextButton(
                onPressed: () {
                  query = result;
                  updateSearchBarLabel(query);
                  displayMemberNew(query);
                  close(context, null);
                },
                child: Text(result),
              ),
            );
          },
        );
      },
    );
  }
}
