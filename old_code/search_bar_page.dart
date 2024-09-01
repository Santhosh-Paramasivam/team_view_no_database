import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({super.key});

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search People"),
        actions: [
          IconButton(onPressed: (){
            showSearch(context: context, delegate: CustomSearchDelegate());
          }, 
          icon: const Icon(Icons.search))
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate 
{
  List<String> searchTerms = 
  [
    'santhosh',
    'bharath',
    'arun prasath'
  ];

  @override
  List<Widget> buildActions(BuildContext context)
  {
    return [
      IconButton(
        onPressed: ()
        {
          query = "";
        }, 
        icon: Icon(Icons.clear)),
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
          title: Text(result)
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
          title: Text(result)
        );
      },
    );
  }
}
