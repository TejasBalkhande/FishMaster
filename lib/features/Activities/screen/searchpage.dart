import 'package:flutter/material.dart';
import 'package:fishmaster/features/Activities/fish_name_string/tamilfish.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  List<TamilFish> filteredFishList = fishList; // Full list
  List<TamilFish> selectedFishes = []; // Store selected fishes

  void _toggleSelection(TamilFish fish) {
    setState(() {
      selectedFishes.contains(fish)
          ? selectedFishes.remove(fish)
          : selectedFishes.add(fish);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Fish'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 12.0), // Add horizontal padding
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filteredFishList.length,
                itemBuilder: (context, index) {
                  TamilFish fish = filteredFishList[index];
                  bool isSelected = selectedFishes.contains(fish);
                  return GestureDetector(
                    onTap: () => _toggleSelection(fish),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10)),
                              image: DecorationImage(
                                image: AssetImage(fish.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              fish.localName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (selectedFishes.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                top: 8.0,
                bottom: MediaQuery.of(context).padding.bottom + 1.0,
              ),
              child: Center(
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selectedFishes);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text("Select Fishes: (${selectedFishes.length})",style: TextStyle(color: Color.fromRGBO(16, 81, 171, 1.0)),),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
