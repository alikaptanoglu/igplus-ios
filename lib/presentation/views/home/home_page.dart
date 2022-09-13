import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:igplus_ios/presentation/blocs/home/cubit/report_cubit.dart';
import 'package:igplus_ios/presentation/resources/colors_manager.dart';
import 'package:igplus_ios/presentation/views/global/info_card.dart';
import 'package:igplus_ios/presentation/views/global/section_title.dart';
import 'package:igplus_ios/presentation/views/home/stats/line-chart.dart';
import 'package:igplus_ios/presentation/views/home/stories/stories_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    context.read<ReportCubit>().init();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: ColorsManager.appBack,
        middle: Container(
          decoration: BoxDecoration(
            color: ColorsManager.cardBack,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                FontAwesomeIcons.user,
                color: ColorsManager.secondarytextColor,
                size: 16.0,
              ),
              SizedBox(width: 6.0),
              Text("Brahimaito", style: TextStyle(fontSize: 14, color: ColorsManager.textColor)),
              SizedBox(width: 4.0),
              Icon(
                FontAwesomeIcons.chevronDown,
                color: ColorsManager.secondarytextColor,
                size: 12.0,
              ),
            ],
          ),
        ),
        trailing: GestureDetector(
          onTap: () => context.read<ReportCubit>().init(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("Refresh", style: TextStyle(fontSize: 12, color: ColorsManager.secondarytextColor)),
              SizedBox(width: 6.0),
              Icon(
                FontAwesomeIcons.arrowsRotate,
                size: 20.0,
                color: ColorsManager.textColor,
              ),
            ],
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
        child: BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            if (state is ReportInProgress) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
            if (state is ReportSuccess) {
              return CupertinoScrollbar(
                thickness: 0,
                child: ListView(
                  children: <Widget>[
                    ProfileCard(
                      followers: state.report.followers,
                      followings: state.report.followings,
                      username: state.accountInfo.username,
                      picture: state.accountInfo.picture,
                    ),
                    LineChartSample(chartData: state.report.followersChartData),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InfoCard(
                          title: "New Followers",
                          icon: FontAwesomeIcons.userPlus,
                          count: state.report.newFollowersCycle,
                          context: context,
                          type: "newFollowers",
                          newFriends: state.report.newFollowers,
                        ),
                        InfoCard(
                          title: "Followers Lost",
                          icon: FontAwesomeIcons.userMinus,
                          count: state.report.lostFollowersCycle,
                          context: context,
                          type: "lostFollowers",
                          newFriends: state.report.lostFollowers,
                        ),
                      ],
                    ),
                    InfoCard(
                      title: "Who Admires You",
                      subTitle: "Find out who's intersted in you",
                      icon: FontAwesomeIcons.solidHeart,
                      count: 0,
                      context: context,
                      style: 1,
                      type: "whoAdmiresYou",
                      newFriends: 0,
                    ),
                    const StoriesList(),
                    const SectionTitle(title: "Important stats", icon: FontAwesomeIcons.chartSimple),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InfoCard(
                          title: "Not Following Back",
                          icon: FontAwesomeIcons.userSlash,
                          count: state.report.notFollowingBackCycle,
                          context: context,
                          type: "notFollowingBack",
                          newFriends: state.report.notFollowingBack,
                        ),
                        InfoCard(
                          title: "You don't follow back",
                          icon: FontAwesomeIcons.userInjured,
                          count: state.report.youDontFollowBackCycle,
                          context: context,
                          type: "youDontFollowBack",
                          newFriends: state.report.youDontFollowBack,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InfoCard(
                          title: "mutual followings",
                          icon: FontAwesomeIcons.userGroup,
                          count: state.report.mutualFollowingsCycle,
                          context: context,
                          type: "mutualFollowings",
                          newFriends: state.report.mutualFollowings,
                        ),
                        InfoCard(
                          title: "You have unfollowed",
                          icon: FontAwesomeIcons.usersSlash,
                          count: state.report.youHaveUnfollowedCycle,
                          context: context,
                          type: "youHaveUnfollowed",
                          newFriends: state.report.youHaveUnfollowed,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else if (state is ReportFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    TextButton(
                      onPressed: () => context.read<ReportCubit>().init(),
                      child: const Text("Retry", style: TextStyle(color: ColorsManager.primaryColor)),
                    ),
                  ],
                ),
              );
            } else {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final int followers;
  final int followings;
  final String username;
  final String picture;
  const ProfileCard({
    Key? key,
    required this.followers,
    required this.followings,
    required this.username,
    required this.picture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 4.0),
      color: ColorsManager.cardBack,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(followers.toString(),
                      style:
                          const TextStyle(fontSize: 20, color: ColorsManager.textColor, fontWeight: FontWeight.bold)),
                ),
                const Text("Followers", style: TextStyle(fontSize: 16, color: ColorsManager.secondarytextColor)),
              ],
            ),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 4.0),
                  alignment: Alignment.centerLeft,
                  width: 90.0,
                  height: 90.0,
                  decoration: BoxDecoration(
                    border: const Border.fromBorderSide(BorderSide(color: ColorsManager.secondarytextColor, width: 2)),
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: NetworkImage(picture),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(followings.toString(),
                      style: TextStyle(fontSize: 20, color: ColorsManager.textColor, fontWeight: FontWeight.bold)),
                ),
                const Text("Following", style: TextStyle(fontSize: 16, color: ColorsManager.secondarytextColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
