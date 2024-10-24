import 'dart:async';
import 'package:flutter/material.dart';

class PongBackground extends StatefulWidget {
  const PongBackground({super.key});

  @override
  _PongBackgroundState createState() => _PongBackgroundState();
}

class _PongBackgroundState extends State<PongBackground> {
  double ballX = 200;
  double ballY = 200;
  double ballDX = 4;
  double ballDY = 4;
  double paddleHeight = 100;
  double paddleWidth = 20;
  double playerPaddleY = 200;
  double computerPaddleY = 200;

  late Timer timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(milliseconds: 8), (Timer t) {
      setState(() {
        ballX += ballDX;
        ballY += ballDY;

        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;

        if (ballY <= 0 || ballY >= screenHeight - 50) {
          ballDY = -ballDY;
        }

        if (ballX <= paddleWidth + 10) {
          if (ballY >= playerPaddleY && ballY <= playerPaddleY + paddleHeight) {
            ballDX = -ballDX;
          }
        } else if (ballX >= screenWidth - paddleWidth - 60) {
          if (ballY >= computerPaddleY && ballY <= computerPaddleY + paddleHeight) {
            ballDX = -ballDX;
          }
        }

        if (ballY > playerPaddleY + paddleHeight / 2) {
          playerPaddleY += 4;
        } else if (ballY < playerPaddleY + paddleHeight / 2) {
          playerPaddleY -= 4;
        }

        if (ballY > computerPaddleY + paddleHeight / 2) {
          computerPaddleY += 4;
        } else if (ballY < computerPaddleY + paddleHeight / 2) {
          computerPaddleY -= 4;
        }

        playerPaddleY = playerPaddleY.clamp(0.0, screenHeight - paddleHeight);
        computerPaddleY = computerPaddleY.clamp(0.0, screenHeight - paddleHeight);

        if (ballX < 0 || ballX > screenWidth) {
          ballX = screenWidth / 2;
          ballY = screenHeight / 2;
          ballDX = 4;
          ballDY = 4;
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black,
        ),
        Positioned(
          left: ballX,
          top: ballY,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: playerPaddleY,
          child: Container(
            width: paddleWidth,
            height: paddleHeight,
            color: Colors.white,
          ),
        ),
        Positioned(
          right: 10,
          top: computerPaddleY,
          child: Container(
            width: paddleWidth,
            height: paddleHeight,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
