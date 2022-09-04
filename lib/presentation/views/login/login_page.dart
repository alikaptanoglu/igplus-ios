import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:igplus_ios/presentation/blocs/login/cubit/instagram_auth_cubit.dart';
import 'package:igplus_ios/presentation/resources/colors_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<InstagramAuthCubit>().init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CupertinoPageScaffold(
          backgroundColor: ColorsManager.appBack,
          child: BlocConsumer<InstagramAuthCubit, InstagramAuthState>(
            listener: (context, state) {
              if (state is InstagramAuthSuccess) {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                GoRouter.of(context).goNamed('tabs');
              }
              if (state is InstagramAuthFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                context.read<InstagramAuthCubit>().emitInstagramAuthInitialState();
              }
            },
            builder: (context, state) {
              if (state is InstagramAuthInProgress) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              if (state is InstagramAuthInitial) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Image.asset(
                          "assets/images/LoginITopImg.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Instant Analysis of your Instagram Freind",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CupertinoButton(
                          color: ColorsManager.primaryColor,
                          child: const Text(
                            "Login with Instagram",
                            style: TextStyle(
                              color: ColorsManager.buttonColor2,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            GoRouter.of(context).pushNamed('instagram_login');
                          }),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "InstaTop V1.0 | Developed by @AitoApps",
                        style: TextStyle(
                          color: ColorsManager.secondarytextColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const Center(
                child: Text('Unknown'),
              );
            },
          ),
        ),
      ),
    );
  }
}
