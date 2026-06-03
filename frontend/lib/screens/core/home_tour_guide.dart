import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/app_colors.dart';

class HomeTourGuide {
  static void show({
    required BuildContext context,
    required GlobalKey navMapKey,
    required GlobalKey navReportKey,
    required GlobalKey navAiKey,
    required GlobalKey navProfileKey,
    required GlobalKey newsCardKey,
    required GlobalKey sosCardKey,
  }) {
    TutorialCoachMark(
      targets: _createTargets(
        context: context,
        navMapKey: navMapKey,
        navReportKey: navReportKey,
        navAiKey: navAiKey,
        navProfileKey: navProfileKey,
        newsCardKey: newsCardKey,
        sosCardKey: sosCardKey,
      ),
      colorShadow: AppColors.primary,
      textSkip: "tour.skip".tr(),
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_tour', true);
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('has_seen_tour', true);
        });
        return true;
      },
    ).show(context: context);
  }

  static List<TargetFocus> _createTargets({
    required BuildContext context,
    required GlobalKey navMapKey,
    required GlobalKey navReportKey,
    required GlobalKey navAiKey,
    required GlobalKey navProfileKey,
    required GlobalKey newsCardKey,
    required GlobalKey sosCardKey,
  }) {
    final isRtl = context.locale.languageCode == 'ar';

    return [
      TargetFocus(
        identify: "news_card_target",
        keyTarget: newsCardKey,
        alignSkip: isRtl ? Alignment.topLeft : Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 20.0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "tour.news_title".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "tour.news_desc".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "sos_card_target",
        keyTarget: sosCardKey,
        alignSkip: isRtl ? Alignment.topLeft : Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 20.0,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "tour.sos_title".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "tour.sos_desc".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "map_target",
        keyTarget: navMapKey,
        alignSkip: isRtl ? Alignment.topLeft : Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "tour.map_title".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "tour.map_desc".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "report_target",
        keyTarget: navReportKey,
        alignSkip: isRtl ? Alignment.topLeft : Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "tour.report_title".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "tour.report_desc".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "ai_target",
        keyTarget: navAiKey,
        alignSkip: isRtl ? Alignment.topRight : Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "tour.ai_title".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "tour.ai_desc".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "profile_target",
        keyTarget: navProfileKey,
        alignSkip: isRtl ? Alignment.topRight : Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "tour.profile_title".tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "tour.profile_desc".tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];
  }
}
