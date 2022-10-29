// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  List<String> blurbList = [];
  List<int> malIDList = [];
  List<bool> favoritedResults = [];
  List<Map> favorites = [];
  List<Map> currentData = [];

  late SharedPreferences prefs;

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
  ];

  static const List<Text> ratings = <Text>[
    Text('g'),
    Text('pg'),
    Text('pg13'),
    Text('r17'),
    Text('rx'),
  ];

  static const List<Text> ratingSFW = <Text>[
    Text('g'),
    Text('pg'),
    Text('pg13'),
  ];

  final List<bool> selectedRatings = <bool>[
    false,
    false,
    false,
    false,
    false,
  ];

  final List<bool> selectedRatingsSFW = <bool>[
    false,
    false,
    false,
  ];

  bool showNSFW = false;

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
    prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    loadFavorites();
    clearLists();
    findSeasonal();
    loadLastText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setState) {
                      return AlertDialog(
                        content: Column(
                          children: [
                            Center(
                              child: Text(
                                  "Anime Finder by Vincent Li for IGME 340"),
                            ),
                            Row(
                              children: [
                                Text("Enable NSFW Results?"),
                                SizedBox(
                                  width: 15,
                                ),
                                FlutterSwitch(
                                    value: showNSFW,
                                    onToggle: (val) {
                                      setState(() {
                                        showNSFW = val;
                                      });
                                    }),
                              ],
                            )
                          ],
                        ),
                      );
                    });
                  },
                );
              },
              icon: Icon(
                Icons.settings,
              ),
            )
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
                          setState(() {
                            resultsToShow = userSelected;
                          });
                        },
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Ratings")),
                      SizedBox(
                        height: 5,
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return ToggleButtons(
                            constraints: BoxConstraints.expand(
                                width: showNSFW
                                    ? constraints.maxWidth / 5.1
                                    : constraints.maxWidth / 3.1),
                            isSelected:
                                showNSFW ? selectedRatings : selectedRatingsSFW,
                            borderColor: Colors.black,
                            selectedBorderColor: Colors.black,
                            borderRadius: BorderRadius.circular(5.0),
                            onPressed: ((index) {
                              setState(() {
                                selectedRatings[index] =
                                    !selectedRatings[index];
                              });
                            }),
                            children: showNSFW ? ratings : ratingSFW,
                          );
                        },
                      ),
                      SizedBox(
                        height: 5,
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
                                saveLastText();
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
                          if (currentData.isNotEmpty)
                            Text('Showing ${currentData.length} results'),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                    ],
                  ),
                Expanded(
                  child: GridView.builder(
                    itemCount: currentData.length,
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
                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return AlertDialog(
                                          content: Column(
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: currentData[index]
                                                        ["images"]["jpg"]
                                                    ["image_url"],
                                                placeholder: (context, url) =>
                                                    const CircularProgressIndicator(),
                                              ),
                                              SizedBox(
                                                height: 20,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      alignment:
                                                          Alignment.topCenter,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          if (!await launchUrl(
                                                              Uri.parse(
                                                                  currentData[
                                                                          index]
                                                                      ["url"]),
                                                              mode: LaunchMode
                                                                  .externalApplication)) {}
                                                        },
                                                        child: Text(
                                                          currentData[index]
                                                              ['title'],
                                                          style: TextStyle(
                                                            color: Colors.blue,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Visibility(
                                                    maintainInteractivity:
                                                        false,
                                                    visible: !favoritedResults[
                                                        index],
                                                    child: Expanded(
                                                      child: Container(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons.star_border,
                                                              color: Colors
                                                                  .orangeAccent,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                favoritedResults[
                                                                        index] =
                                                                    true;
                                                                favorites.add(
                                                                    currentData[
                                                                        index]);
                                                                saveFavorites();
                                                              });
                                                            },
                                                          )),
                                                    ),
                                                  ),
                                                  Visibility(
                                                    maintainInteractivity:
                                                        false,
                                                    visible:
                                                        favoritedResults[index],
                                                    child: Expanded(
                                                      child: Container(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons.star,
                                                              color: Colors
                                                                  .orangeAccent,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                favoritedResults[
                                                                        index] =
                                                                    false;
                                                                favorites.removeWhere((element) =>
                                                                    element[
                                                                        "mal_id"] ==
                                                                    currentData[
                                                                            index]
                                                                        [
                                                                        "mal_id"]);
                                                                saveFavorites();
                                                              });
                                                            },
                                                          )),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Text(currentData[index]
                                                      ["synopsis"]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  });
                            },
                            child: CachedNetworkImage(
                              imageUrl: currentData[index]["images"]["jpg"]
                                  ["image_url"],
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
                            loadFavorites();
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
                ),
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
        if (!showNSFW &&
            (jData["data"][i]["rating"] == "R - 17+" ||
                jData["data"][i]["rating"] == "Rx - Hentai")) {
          continue;
        }
        setState(() {
          currentData.add(jData["data"][i]);
          bool didSetFavorite = false;
          for (int j = 0; j < favorites.length; j++) {
            if (favorites[j]["mal_id"] == currentData[i]["mal_id"]) {
              favoritedResults.add(true);
              didSetFavorite = true;
              break;
            }
          }
          if (!didSetFavorite) favoritedResults.add(false);
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
          if (!showNSFW &&
              (jData["data"][i]["rating"] == "R - 17+" ||
                  jData["data"][i]["rating"] == "Rx - Hentai")) {
            continue;
          }
          setState(() {
            currentData.add(jData["data"][i]);
            bool didSetFavorite = false;
            for (int j = 0; j < favorites.length; j++) {
              if (favorites[j]["mal_id"] == currentData[currentData.length-1]["mal_id"]) {
                favoritedResults.add(true);
                didSetFavorite = true;
                break;
              }
            }
            if (!didSetFavorite) favoritedResults.add(false);
          });
        }
        if (jData["pagination"]["has_next_page"] &&
            pageNumber < (int.parse(resultsToShow!) / 25) &&
            currentData.length < int.parse(resultsToShow!)) {
          pageNumber++;

          if (ratingQuery != null) {
            await findCustom(ratingQuery: ratingQuery);
          } else {
            await findCustom();
          }
        } else {
          pageNumber = 1;
          if (currentData.length > int.parse(resultsToShow!)) {
            currentData.removeRange(
                int.parse(resultsToShow!), currentData.length);
          }
          setState(() {
            isSearching = false;
          });
        }
      }
      return;
    }
  }

  loadFavorites() {
    String? m = prefs.getString('favoritesMap');
    var myMap = jsonDecode(m!);
    setState(() {
      for (int i = 0; i < myMap.length; i++) {
        currentData.add(myMap[i]);
        favoritedResults.add(true);
        bool shouldAdd = true;
        for (int j = 0; j < favorites.length; j++) {
          if (favorites[j]["mal_id"] == currentData[i]["mal_id"]) {
            shouldAdd = false;
            break;
          }
        }

        if (shouldAdd) {
          favorites.add(myMap[i]);
        }
      }
    });
  }

  loadLastText() {
    String? str = prefs.getString("lastSearched");

    setState(() {
      _field01.text = str!;
    });
  }

  saveLastText() {
    prefs.setString("lastSearched", _field01.text);
  }

  saveFavorites() {
    String mapData = json.encode(favorites);
    prefs.setString('favoritesMap', mapData);
  }

  void clearLists() {
    setState(() {
      shouldDoDefault = true;
      currentData.clear();
      favoritedResults.clear();
    });
  }
}
