import 'package:flutter/material.dart';
import '../beacon_list/beacon_list_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Beacon Finder")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Find beacon devices around you",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(
                  255,
                  255,
                  165,
                  68,
                ), // Button background color
                foregroundColor: Colors.black, // Button text color (Font color)
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BeaconListPage()),
                );
              },
              child: Text("Find"),
            ),
          ],
        ),
      ),
    );
  }
}
