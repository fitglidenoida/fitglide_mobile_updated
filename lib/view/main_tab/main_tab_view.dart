import 'package:fitglide_mobile_application/view/main_tab/select_view.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/tab_button.dart';
import 'package:flutter/material.dart';

import '../home/home_view.dart';
import '../photo_progress/photo_progress_view.dart';
import '../profile/profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: PageStorage(bucket: pageBucket, child: _buildCurrentTabView()),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter, // Align the FAB to the bottom
        child: Padding(
          padding: const EdgeInsets.only(bottom: 30.0), // Adjust the bottom padding to move the FAB downwards
          child: SizedBox(
            width: 60,
            height: 60,
            child: InkWell(
              onTap: () {},
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: TColor.primaryG,
                  ),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.search, color: TColor.white, size: 35),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0, // Remove shadow
        color: TColor.white, // Keep background color white
        child: Container(
          height: kToolbarHeight,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey, // Grey border on top
                width: 1, // Adjust thickness if necessary
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TabButton(
                icon: "assets/img/home_tab.png",
                selectIcon: "assets/img/home_tab_select.png",
                isActive: selectTab == 0,
                onTap: () {
                  setState(() {
                    selectTab = 0;
                  });
                },
              ),
              TabButton(
                icon: "assets/img/activity_tab.png",
                selectIcon: "assets/img/activity_tab_select.png",
                isActive: selectTab == 1,
                onTap: () {
                  setState(() {
                    selectTab = 1;
                  });
                },
              ),
              const SizedBox(width: 40),
              TabButton(
                icon: "assets/img/camera_tab.png",
                selectIcon: "assets/img/camera_tab_select.png",
                isActive: selectTab == 2,
                onTap: () {
                  setState(() {
                    selectTab = 2;
                  });
                },
              ),
              TabButton(
                icon: "assets/img/profile_tab.png",
                selectIcon: "assets/img/profile_tab_select.png",
                isActive: selectTab == 3,
                onTap: () {
                  setState(() {
                    selectTab = 3;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabView() {
    switch (selectTab) {
      case 0:
        return const HomeView();
      case 1:
        return const SelectView();
      case 2:
        return const PhotoProgressView();
      case 3:
        return const ProfileView();
      default:
        return const HomeView(); // Default case
    }
  }
}
