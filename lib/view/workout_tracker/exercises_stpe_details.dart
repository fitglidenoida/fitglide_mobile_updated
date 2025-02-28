import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/home/finished_workout_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/step_detail_row.dart';

class ExercisesStepDetails extends StatefulWidget {
  final Map<String, dynamic> eObj;
  final String documentId;

  const ExercisesStepDetails({super.key, required this.eObj, required this.documentId});

  @override
  State<ExercisesStepDetails> createState() => _ExercisesStepDetailsState();
}

class _ExercisesStepDetailsState extends State<ExercisesStepDetails> {
  List<Map<String, dynamic>> stepArr = [];

  @override
  void initState() {
    super.initState();
    _initializeSteps();
  }

  void _initializeSteps() {
    stepArr = (widget.eObj["set"] as List<dynamic>? ?? []).map((step) => {
          "image": "assets/img/img_${(stepArr.length % 2) + 1}.png",
          "title": step['title']?.toString() ?? step.toString().trim(),
          "value": step['value']?.toString() ?? 'Unknown',
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: media.width,
                    height: media.width * 0.43,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      widget.eObj["image"] ?? "assets/img/video_temp.png",
                      width: media.width,
                      height: media.width * 0.43,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          "assets/img/video_temp.png",
                          width: media.width,
                          height: media.width * 0.43,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                  Container(
                    width: media.width,
                    height: media.width * 0.43,
                    decoration: BoxDecoration(
                      color: TColor.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Add video playback logic here
                      debugPrint('Video playback triggered for ${widget.eObj["title"]}');
                    },
                    icon: Image.asset(
                      "assets/img/Play.png",
                      width: 30,
                      height: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                widget.eObj["title"].toString(),
                style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                "${widget.eObj["difficulty"] ?? 'Easy'} | ${widget.eObj["calories"] ?? 'N/A'} Calories Burn",
                style: TextStyle(color: TColor.gray, fontSize: 12),
              ),
              const SizedBox(height: 15),
              Text(
                "Descriptions",
                style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ReadMoreText(
                widget.eObj['description']?.toString() ?? 'Description not available.',
                trimLines: 4,
                colorClickableText: TColor.black,
                trimMode: TrimMode.Line,
                trimCollapsedText: ' Read More ...',
                trimExpandedText: ' Read Less',
                style: TextStyle(color: TColor.gray, fontSize: 12),
                moreStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "How To Do It",
                    style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "${stepArr.length} Sets",
                      style: TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                  ),
                ],
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: stepArr.length,
                itemBuilder: (context, index) {
                  var sObj = stepArr[index] as Map? ?? {};
                  return StepDetailRow(
                    sObj: sObj,
                    isLast: index == stepArr.length - 1,
                  );
                },
              ),
              const SizedBox(height: 15),
              Text(
                "Custom Repetitions",
                style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 150,
                child: CupertinoPicker.builder(
                  itemExtent: 40,
                  selectionOverlay: Container(
                    width: double.maxFinite,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: TColor.gray.withOpacity(0.2), width: 1),
                        bottom: BorderSide(color: TColor.gray.withOpacity(0.2), width: 1),
                      ),
                    ),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      // Update widget.eObj with custom repetitions if needed
                      widget.eObj['repetitions'] = (index + 1) * 15;
                    });
                  },
                  childCount: 60,
                  itemBuilder: (context, index) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/img/burn.png",
                          width: 15,
                          height: 15,
                          fit: BoxFit.contain,
                        ),
                        Text(
                          " ${(index + 1) * 15} Calories Burn",
                          style: TextStyle(color: TColor.gray, fontSize: 10),
                        ),
                        Text(
                          " ${index + 1} ",
                          style: TextStyle(color: TColor.gray, fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          " times",
                          style: TextStyle(color: TColor.gray, fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (!(widget.eObj["completed"] as bool? ?? false))
                RoundButton(
                  title: "Finish",
                  elevation: 0,
                  onPressed: () async {
                    try {
                      debugPrint('Attempting to update workout with documentId: ${widget.documentId}');
                      final response = await ApiService.updateWorkoutPlan(widget.documentId, {'completed': true});
                      debugPrint('Update response: $response');
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const FinishedWorkoutView()),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error finishing workout: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to finish workout: $e')),
                        );
                      }
                    }
                  },
                ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}