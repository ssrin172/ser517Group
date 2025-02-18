import 'package:flutter/material.dart';
import 'package:frontend/views/beacon_list/beacon_list_page.dart';

Widget beaconButton(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BeaconListPage()),
      );
    },
    child: Text("Find Beacons"),
  );
}
