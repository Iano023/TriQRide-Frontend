import 'package:flutter/material.dart';

class FarePriceListPage extends StatelessWidget {
  const FarePriceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final images = [
      'farematrix3.jpg',
      'farematrix4.jpg',
      'farematrix5.jpg',
      'farematrix6.jpg',
      'farematrix7.jpg',
      'farematrix8.jpg',
      'farematrix9.jpg',
      'farematrix10.jpg',
      'farematrix11.jpg',
      'farematrix1.jpg',
      'farematrix2.jpg',
      'farematrix12.jpg',
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/municipalhall.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Candelaria Tricycle Fare Matrix',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const Text(
              'as of January 2024',
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ...images.map((img) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.asset('assets/images/$img', scale: 4.0),
                )),
          ],
        ),
      ),
    );
  }
}
