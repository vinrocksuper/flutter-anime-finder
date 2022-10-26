// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'bubbles',
      ),
      home: const MyHomePage(title: 'Anime Finder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _field01 = TextEditingController();
  // String apiKey = 'MrCl1EisvRz2N6SidPhG66hv471TSO8W';
  // use C# style string templating with {#} and params that relate to the #
  String seasonalAPI = 'https://api.jikan.moe/v4/seasons/now?page={0}';
  String searchAPI = 'https://api.jikan.moe/v4/anime?q={0}&rating={1}&page={2}';

  List<String> urlList = [];
  List<String> titleList = [];
  List<String> creatorList = [];

  var numResults = [
    DropdownMenuItem(
      value: '25',
      child: Text('25'),
    ),
    DropdownMenuItem(
      value: '50',
      child: Text('50'),
    ),
    DropdownMenuItem(
      value: '75',
      child: Text('75'),
    ),
    DropdownMenuItem(
      value: '100',
      child: Text('100'),
    ),
    DropdownMenuItem(
      value: '100',
      child: Text('100'),
    ),
  ];

  static const List<Text> ratings = <Text>[
    Text('g'),
    Text('pg'),
    Text('pg13'),
    Text('r17'),
    Text('rx'),
  ];

  final List<bool> selectedRatings = <bool>[
    false,
    false,
    false,
    false,
    false,
  ];

  String? resultsToShow = '25';

  int index = 0;
  int pageNumber = 1;

  bool isSearching = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    findSeasonal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            Icon(
              Icons.settings,
            ),
          ],
          bottom: isSearching
              ? PreferredSize(
                  preferredSize: Size.fromHeight(6.0),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.red.withOpacity(0.3),
                    valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
                    value: null,
                  ),
                )
              : PreferredSize(
                  preferredSize: Size.fromHeight(6),
                  child: Container(),
                ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (index == 1)
                  Column(
                    children: [
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a search term';
                          }
                          return null;
                        },
                        controller: _field01,
                        keyboardType: TextInputType.text,
                        textInputAction:
                            TextInputAction.next, // goes to next input field
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text('Search Term'),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          label: Text('Number of Results'),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                        items: numResults,
                        value: resultsToShow,
                        onChanged: (userSelected) {
                          // needs a nullable named param
                          setState(() {
                            resultsToShow = userSelected;
                          });
                        },
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ToggleButtons(
                        isSelected: selectedRatings,
                        onPressed: ((index) {
                          setState(() {
                            selectedRatings[index] = !selectedRatings[index];
                          });
                        }),
                        children: ratings,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              clearLists();
                            },
                            child: Text('Reset'),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_formKey.currentState!.validate()) {
                                clearLists();
                                findCustom();
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.search),
                                SizedBox(
                                  width: 10,
                                ),
                                Text('Search'),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          if (urlList.isNotEmpty)
                            Text('Showing ${urlList.length} results'),
                        ],
                      ),
                    ],
                  ),
                Expanded(
                  child: GridView.builder(
                    itemCount: urlList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent:
                          175, // stretches items vertically to the number if defined, otherwise it's equal in Width | Height
                    ),
                    itemBuilder: ((context, index) {
                      return GridTile(
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      content: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: urlList[index],
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Text(titleList[index]),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          InkWell(
                                            onTap: () async {
                                              if (!await launchUrl(
                                                  Uri.parse(urlList[index]),
                                                  mode: LaunchMode
                                                      .externalApplication)) {}
                                            },
                                            child: Text(
                                              urlList[index],
                                              style: TextStyle(
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  });
                            },
                            child: CachedNetworkImage(
                              imageUrl: urlList[index],
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                BottomNavigationBar(
                  currentIndex: index,
                  onTap: (value) {
                    if (!isSearching) {
                      setState(() {
                        index = value;
                        switch (index) {
                          case 0:
                            clearLists();
                            findSeasonal();
                            break;
                          case 1:
                            clearLists();
                            break;
                          case 2:
                            clearLists();
                            break;
                        }
                      });
                    }
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.live_tv,
                      ),
                      label: "Seasonal",
                      backgroundColor: Colors.pink,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.search,
                      ),
                      label: "Search",
                      backgroundColor: Colors.green,
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.star,
                      ),
                      label: "Starred",
                      backgroundColor: Colors.amberAccent,
                    ),
                  ],
                )
              ],
            ),
          ),
        ));
  }

  Future getAPIResponse(String url) async {
    String fullURL = url;
    var response = await http.get(Uri.parse(fullURL));
    return jsonDecode(response.body);
  }

  Future findSeasonal() async {
    String customURL = seasonalAPI.replaceAll('{0}', pageNumber.toString());
    setState(() {
      isSearching = true;
    });

    var jData = await getAPIResponse(customURL);

    if (jData["data"] != null) {
      for (int i = 0; i < jData["data"].length; i++) {
        setState(() {
          urlList.add(jData["data"][i]["images"]["jpg"]["image_url"]);
          titleList.add(jData["data"][i]["title"]);
        });
      }

      if (jData["pagination"]["has_next_page"]) {
        pageNumber++;
        await findSeasonal();
      } else {
        pageNumber = 1;
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  bool shouldDoDefault = true;
  Future findCustom({ratingQuery}) async {
    String customURL = searchAPI.replaceAll('{0}', _field01.text);

    if (ratingQuery != null) {
      customURL = customURL.replaceAll('{1}', ratingQuery);
    } else {
      customURL = customURL.replaceAll('&rating={1}', '');
    }

    // if the rating query is null (which is the first run)
    if (ratingQuery == null) {
      for (int i = 0; i < selectedRatings.length; i++) {
        if (selectedRatings[i]) {
          shouldDoDefault = false;
          await findCustom(ratingQuery: ratings[i].data);
        }
      }
    }
    if (shouldDoDefault || ratingQuery != null) {
      customURL = customURL.replaceAll('{2}', pageNumber.toString());
      setState(() {
        isSearching = true;
      });
      var jData = await getAPIResponse(customURL);

      if (jData["data"] != null) {
        for (int i = 0; i < jData["data"].length; i++) {
          setState(() {
            urlList.add(jData["data"][i]["images"]["jpg"]["image_url"]);
            titleList.add(jData["data"][i]["title"]);
          });
        }
        if (jData["pagination"]["has_next_page"] &&
            pageNumber < (int.parse(resultsToShow!) / 25) &&
            urlList.length < int.parse(resultsToShow!)) {
          pageNumber++;

          if (ratingQuery != null) {
            await findCustom(ratingQuery: ratingQuery);
          } else {
            await findCustom();
          }
        } else {
          pageNumber = 1;
          if (urlList.length > int.parse(resultsToShow!)) {
            urlList.removeRange(int.parse(resultsToShow!), urlList.length);
            titleList.removeRange(int.parse(resultsToShow!), titleList.length);
          }
          setState(() {
            isSearching = false;
          });
        }
      }
      return;
    }
  }

  Future loadFavorites() async {
    // TODO
  }

  Future saveFavorites() async {
    // TODO
  }

  void clearLists() {
    setState(() {
      shouldDoDefault = true;
      urlList.clear();
      titleList.clear();
      creatorList.clear();
    });
  }
}
