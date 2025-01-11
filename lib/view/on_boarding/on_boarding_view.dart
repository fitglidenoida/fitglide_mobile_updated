import 'package:fitglide_mobile_application/view/login/signup_view.dart';
import '../../common_widget/on_boarding_page.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView> {
  int selectPage = 0;
  PageController controller = PageController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller.addListener(() {
        selectPage = controller.page?.round() ?? 0;

      setState(() {
        
      });
    });
  }

  List pageArr = [
    {
      "title": "Track your Fitness",
      "subtitle":
          "Your journey starts here – whether you're unsure how to begin or need expert guidance, we're here to help you achieve your fitness goals with personalized support every step of the way!",
      "image": "assets/img/on_1.png"
    },
    {
      "title": "Let's Burn",
      "subtitle":
          "Set Your Goals on Fire – Burn Fat and Unleash Your Best Self! Your Transformation Starts Here.",
      "image": "assets/img/on_2.png"
    },
    {
      "title": "Eat Well",
      "subtitle":
          "Nourish Your Body the Right Way – Embrace healthy eating habits tailored to your goals. Discover personalized Indian diet plans designed to boost your overall health and well-being.",
      "image": "assets/img/on_3.png"
    },
    {
      "title": "Improve Your\nStamina",
      "subtitle":
          "Build Endurance, One Step at a Time - Prioritize rest and recovery to unlock your full potential and sustain peak performance.",
      "image": "assets/img/on_4.png"
    },
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: TColor.white,
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          PageView.builder(
              controller: controller,
              itemCount: pageArr.length,
              itemBuilder: (context, index) {
                var pObj = pageArr[index] as Map? ?? {};
                return OnBoardingPage(pObj: pObj) ;
              }),

          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [

                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    color: TColor.primaryColor1,
                    value: (selectPage + 1) / 4 ,
                    strokeWidth: 2,
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: TColor.primaryColor1, borderRadius: BorderRadius.circular(35)),
                  child: IconButton(icon: Icon( Icons.navigate_next, color: TColor.white, ), onPressed: (){
          
                      if(selectPage < 3) {
          
                         selectPage = selectPage + 1;

                        controller.animateToPage(selectPage, duration: const Duration(milliseconds: 600), curve: Curves.bounceInOut);
                        
                        // controller.jumpToPage(selectPage);
                        
                          setState(() {
                            
                          });
          
                      }else{
                        // Open Welcome Screen
                        print("Open Welcome Screen");
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpView() ));
                      }
                      
                  },),
                ),

                
              ],
            ),
          )
        ],
      ),
    );
  }
}
