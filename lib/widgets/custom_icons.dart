import 'package:flutter/material.dart';

class ClientIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ClientIcon({
    super.key,
    this.size = 40.0,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Client face
          Positioned(
            left: 0,
            top: size * 0.1,
            child: Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size * 0.3),
              ),
            ),
          ),
          
          // Card icon
          Positioned(
            right: 0,
            bottom: size * 0.1,
            child: Container(
              width: size * 0.6,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
              child: Center(
                child: Container(
                  width: size * 0.4,
                  height: size * 0.05,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LawyerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const LawyerIcon({
    super.key,
    this.size = 40.0,
    this.color = Colors.blueGrey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Lawyer head
          Positioned(
            left: size * 0.25,
            top: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
            ),
          ),
          
          // Lawyer body (suit)
          Positioned(
            left: size * 0.15,
            bottom: 0,
            child: Container(
              width: size * 0.7,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.1),
                  topRight: Radius.circular(size * 0.1),
                ),
              ),
            ),
          ),
          
          // Tie
          Positioned(
            left: size * 0.4,
            bottom: 0,
            child: Container(
              width: size * 0.2,
              height: size * 0.4,
              decoration: const BoxDecoration(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}