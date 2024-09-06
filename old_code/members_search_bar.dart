import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class MemberSearchBar extends StatefulWidget {
  const MemberSearchBar({super.key});

  @override
  State<MemberSearchBar> createState() => _MemberSearchBarState();
}

class _MemberSearchBarState extends State<MemberSearchBar> {

  late List<String> searchTerms;
  late List<String> jsonSearchTerms;
  late Map<String,dynamic> jsonData;
  late int appUserInstitutionID;
  late String searchedUser;


  @override
  initState()
  {
    searchTerms = [
    'santhosh',
    'bharath',
    'arun prasath'
    ];

    jsonSearchTerms = [];
    appUserInstitutionID = 1;
    updateOptions("");
  }

  void sendBackString(String data)
  {
    print("data: $data");
  }

  Future<void> updateOptions(String searchSubstring) async {
  jsonSearchTerms.clear();

  String jsonString = await rootBundle.loadString('assets/members.json');
  setState(() {
    jsonData = json.decode(jsonString);

    // Using List<dynamic> to avoid type issues
    List<dynamic> filteredMembers = jsonData['institution_members']
        .where((member) =>
            member['name'] != null &&
            member['name'].toString().toLowerCase().contains(searchSubstring.toLowerCase()))
        .toList();

    // Print the filtered members
    print("Members with name containing '$searchSubstring':");
    for (var member in filteredMembers) {
    print((member as Map<String, dynamic>)['name']);
    jsonSearchTerms.add((member)['name']); // Cast to Map<String, dynamic>
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search People"),
        actions: [
          IconButton(onPressed: (){
            showSearch(context: context, delegate: CustomSearchDelegate(jsonSearchTerms, updateOptions, sendBackString));
          }, 
          icon: const Icon(Icons.search))
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate 
{
  List<String> searchTerms;
  final Future<void> Function(String query) updateOptions;
  void Function(String) sendBackString;

  CustomSearchDelegate(this.searchTerms, this.updateOptions, this.sendBackString);

  Future<void> onQueryChanged(String query) async {
    await updateOptions(query);
  }

  @override
  List<Widget> buildActions(BuildContext context)
  {
    return [
      IconButton(
        onPressed: ()
        {
          query = "";
        }, 
        icon: const Icon(Icons.clear)),
      IconButton(
        onPressed: ()
        {
          sendBackString(query);
        }, 
        icon: const Icon(Icons.send)),
    ];
  }

  @override
  Widget buildLeading(BuildContext context)
  {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: ()
      {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context)
  {
    onQueryChanged(query);
    List<String> matchQuery = [];
    for(var person in searchTerms)
    {
      if(person.toLowerCase().contains(query.toLowerCase()) && matchQuery.length < 5)
      {
        matchQuery.add(person);
      }
    }

    return ListView.builder
    (
      itemCount: matchQuery.length,
      itemBuilder: (context, index)
      {
        var result = matchQuery[index];
        return ListTile
        (
          title: TextButton(
          onPressed: ()
          {
            query = result; 
            matchQuery = [];
            showResults(context);
            sendBackString(query);
            }, 
          child: Text(result))
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context){
    List<String> matchQuery = [];
    for(var person in searchTerms)
    {
      if(person.toLowerCase().contains(query.toLowerCase()) && matchQuery.length < 5 && query.isNotEmpty)
      {
        matchQuery.add(person);
      }
    }

    return ListView.builder
    (
      itemCount: matchQuery.length,
      itemBuilder: (context, index)
      {
        var result = matchQuery[index];
        return ListTile
        (
          title: TextButton(
          onPressed: ()
          {
            query = result; 
            matchQuery = [];
            showResults(context);
            sendBackString(query);
            close(context, null);
          }, 
          child: Text(result))
        );
      },
    );
  }
}
