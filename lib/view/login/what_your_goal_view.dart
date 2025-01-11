import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitglide_mobile_application/view/home/home_view.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import 'package:flutter/material.dart';

class WhatsYourGoalView extends StatefulWidget {
  const WhatsYourGoalView({super.key});

  @override
  State<WhatsYourGoalView> createState() => _WhatsYourGoalViewState();
}

class _WhatsYourGoalViewState extends State<WhatsYourGoalView> {


    CarouselSliderController buttonCarouselController = CarouselSliderController();

    List goalArr = [
      {"image":"assets/img/goal-1.png","title":"Body Tranformation","subtitle":"From Now to Wow:\nYour Journey Starts Here."},
        {"image":"assets/img/goal-2.png","title":"Strength Unleashed","subtitle":"Unleash Your Inner Power\nOne Rep at a Time."},
          {"image":"assets/img/goal-3.png","title":"Weight Loss","subtitle":"Say Goodbye to Extra Pounds\nand Hello to a Healthier You."},
    ];

  @override
  Widget build(BuildContext context) {
   var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
          child: Stack(
        children: [
          Center(
            child: CarouselSlider(
              items: goalArr.map(
                      (gObj) => Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: TColor.primaryG,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(vertical: media.width * 0.1, horizontal: 25),
                          alignment: Alignment.center,
                          child: FittedBox(
                            child: Column(
                              children: [
                                Image.asset(
                              gObj["image"].toString(),
                              width: media.width * 0.5,
                              fit: BoxFit.fitWidth,
                            ),
                            
                            SizedBox(height: media.width * 0.1,),
                            Text(
                              gObj["title"].toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            
                            Container(width: media.width * 0.1, height: 1, color: TColor.white,),

                            SizedBox(height: media.width * 0.1,),
                            Text(
                              gObj["subtitle"].toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                              
                              ],
                            
                            ),
                          ),


                          ),
                          )
                  .toList(),
                  carouselController: buttonCarouselController,
        options: CarouselOptions(
          autoPlay: false,
          enlargeCenterPage: true,
          viewportFraction: 0.7,
          aspectRatio: 0.74,
          initialPage: 2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            width: media.width,
            child: Column(
              children: [
                SizedBox(height: media.width * 0.05), // Spacing after the image

                // Heading Text
                Text(
                  "What is your goal?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
SizedBox(height: media.width * 0.1,),                
                Text(
                  "Let's tailor your journey\nto your goal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  height: media.width * 0.05,
                ),
                RoundButton(
                  title: "Confirm",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
