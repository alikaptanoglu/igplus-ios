// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:igreports/data_source/source/headers_datasource.dart';
// import 'package:igreports/models/ig_headers.dart';

import 'dart:convert';

import 'package:igplus_ios/data/models/account_info_model.dart';
import 'package:http/http.dart' as http;
import 'package:igplus_ios/data/sources/local/local_datasource.dart';
import 'package:igplus_ios/domain/entities/friend.dart';
import 'package:igplus_ios/domain/usecases/get_friends_from_local_use_case.dart';

import '../../constants.dart';
import '../../failure.dart';
import '../../models/friend_model.dart';

abstract class InstagramDataSource {
  Future<AccountInfoModel> getAccountInfoByUsername({required String username, required Map<String, String> headers});
  Future<AccountInfoModel> getAccountInfoById({required String igUserId, required Map<String, String> headers});
  Future<List<FriendModel>> getFollowers({
    required String igUserId,
    required Map<String, String> headers,
    String? maxIdString,
    required List<Friend> cachedFollowersList,
  });
  Future<List<FriendModel>> getFollowings({required String igUserId, required Map<String, String> headers});
}

class InstagramDataSourceImp extends InstagramDataSource {
  final http.Client client;

  InstagramDataSourceImp({required this.client});

  @override
  Future<AccountInfoModel> getAccountInfoById({required String igUserId, required Map<String, String> headers}) async {
    final response = await client.get(Uri.parse(InstagramUrls.getAccountInfoById(igUserId)), headers: headers);

    if (response.statusCode == 200) {
      return AccountInfoModel.fromJsonById(jsonDecode(response.body));
    } else {
      throw const ServerFailure("Failed to get account info by ID");
    }
  }

  @override
  Future<AccountInfoModel> getAccountInfoByUsername(
      {required String username, required Map<String, String> headers}) async {
    final response = await client.get(Uri.parse(InstagramUrls.getAccountInfoByUsername(username)), headers: headers);

    if (response.statusCode == 200) {
      return AccountInfoModel.fromJsonByUsername(jsonDecode(response.body));
    } else {
      throw const ServerFailure("Failed to get account info by username");
    }
  }

  @override
  Future<List<FriendModel>> getFollowers({
    required String igUserId,
    required Map<String, String> headers,
    String? maxIdString,
    required List<Friend> cachedFollowersList,
  }) async {
    List<FriendModel> friendsList = [];
    String? nextMaxId = "";
    int nbrRequests = 1;
    const int requestsLimit = 20;

    final response =
        await client.get(Uri.parse(InstagramUrls.getFollowers(igUserId, maxIdString ?? "")), headers: headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // search for last cached friend to get only new friends
      if (cachedFollowersList.isNotEmpty) {
        bool lastCachedFollowersDetected = false;
        int currentCase = 0;
        final List<dynamic> users = body["users"];
        FriendModel lastFriend = FriendModel.fromJson(users.last);

        int lastFriendIndexInCachedList =
            cachedFollowersList.indexWhere((element) => element.igUserId == lastFriend.igUserId);
        List<Friend> tmpCachedFriendList = cachedFollowersList.sublist(0, lastFriendIndexInCachedList);

        // remove friends from cached list where igUserId is not in friends list (remove unfollowed)
        tmpCachedFriendList.removeWhere((element) => users.indexWhere((e) => e['pk'] == element.igUserId) == -1);

        while (lastCachedFollowersDetected == false) {
          Friend lastCachedFriend = cachedFollowersList[currentCase];
          int lastCachedFriendIndex = body["users"].indexWhere((friend) => friend["pk"] == lastCachedFriend.igUserId);

          // test if last cached friends is still friend or no
          if (lastCachedFriendIndex != -1) {
            lastCachedFollowersDetected = true;
            if (lastCachedFriendIndex != 0) {
              List<dynamic> newFriendsList = body["users"]
                  .sublist(0, lastCachedFriendIndex)
                  .map((friend) => FriendModel.fromJson(friend))
                  .toList();
              // friendsList.removeWhere((element) => false);
              friendsList = [
                ...newFriendsList,
                ...cachedFollowersList.map((friend) => FriendModel.fromFriend(friend)).toList()
              ];
              print(friendsList);
            }
          } else {
            cachedFollowersList.removeAt(currentCase);
            currentCase++;
          }
        }
      } else {
        nextMaxId = body['next_max_id'];
        List<dynamic> users = body["users"];
        friendsList = users.map((friend) => FriendModel.fromJson(friend)).toList();

        while (nextMaxId != null && nbrRequests < requestsLimit) {
          nbrRequests++;
          String maxIdString = "";
          if (nextMaxId != "") {
            await Future.delayed(const Duration(seconds: 3));
            maxIdString = "&max_id=$nextMaxId";
            nextMaxId = null;

            final response =
                await client.get(Uri.parse(InstagramUrls.getFollowers(igUserId, maxIdString)), headers: headers);

            final rs = jsonDecode(response.body);
            final List<dynamic> users = rs['users'];

            if (users.isNotEmpty) {
              nextMaxId = rs['next_max_id'];
              friendsList.addAll(users.map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList());
            }
          } else {
            break;
          }
        }
      }

      return friendsList;
    } else {
      throw const ServerFailure("Failed to get followers from Instagram");
    }
  }

  @override
  Future<List<FriendModel>> getFollowings(
      {required String igUserId, required Map<String, String> headers, String? maxIdString}) async {
    List<dynamic>? friendsList = [];
    String? nextMaxId = "";
    int nbrRequests = 1;
    const int requestsLimit = 20;

    final response =
        await client.get(Uri.parse(InstagramUrls.getFollowings(igUserId, maxIdString ?? "")), headers: headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      nextMaxId = body['next_max_id'];
      friendsList = body["users"] as List<dynamic>;

      while (nextMaxId != null && nbrRequests < requestsLimit) {
        nbrRequests++;
        String maxIdString = "";
        if (nextMaxId != "") {
          await Future.delayed(const Duration(seconds: 3));
          maxIdString = "&max_id=$nextMaxId";
          nextMaxId = null;

          final response =
              await client.get(Uri.parse(InstagramUrls.getFollowings(igUserId, maxIdString)), headers: headers);

          final rs = jsonDecode(response.body);

          if (rs['users'] != null) {
            nextMaxId = rs['next_max_id'];
            rs['users'].forEach((user) {
              friendsList?.add(user);
            });
          }
        } else {
          break;
        }
      }

      return friendsList.map((f) => FriendModel.fromJson(f as Map<String, dynamic>)).toList();
    } else {
      throw const ServerFailure("Failed to get followers from Instagram");
    }
  }
}

// //https://github.com/postaddictme/instagram-php-scraper
// class InstagramDataSource {
//   const InstagramDataSource({required this.headersDataSource});
//   final HeadersDataSource headersDataSource;

//   //final  BaseUrl = "https://i.instagram.com/api/v1";

//   Future<http.Response> getUserInfo({required String igUserId, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/users/$igUserId/info');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

//   //https://www.instagram.com/$username/?__a=1
//   Future<http.Response> getUserInfoByUsername({required String username, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/users/web_profile_info/?username=$username');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

//   //1-https://i.instagram.com/api/v1/media/2445116530512128408/info
//   //2-https://www.instagram.com/p/{code}/?__a=1
//   // we use the seconde url
//   Future<http.Response> getMediaInfoByUrl({required Uri uri, required IgHeaders igHeaders}) async {
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

//   Future<http.Response> getUserStories({required String igUserId, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/feed/reels_media/?reel_ids=$igUserId');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

//   // https://i.instagram.com/api/v1/friendships/show/4280661977
//   Future<http.Response> getFriendshipStatus({required String friendIgUserId, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/friendships/show/$friendIgUserId');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

// //https://i.instagram.com/api/v1/feed/user/47092259342/story/
//   Future<http.Response> getStories({required String IgUserId, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/feed/user/$IgUserId/story/');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

//   //https://www.instagram.com/graphql/query/?query_hash=e769aa130647d2354c40ea6a439bfc08&variables={variables}
//   Future<http.Response> getUserMedias({required String username, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/users/web_profile_info/?username=$username');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;
//   }

// // https://i.instagram.com/api/v1/tags/search/?q=tiktok
//   Future<http.Response> getHashtagsRelatedTo({required String keyword, required IgHeaders igHeaders}) async {
//     final uri = Uri.parse('https://i.instagram.com/api/v1/tags/search/?q=$keyword');
//     http.Response response = await http.get(uri, headers: igHeaders.toJson());
//     return response;

//     // const mainHost = 'www.instagram.com';
//     // const mainHost = 'i.instagram.com';
//     // var queryParameters = {
//     //   'context': 'hashtag',
//     //   'query': keyword,
//     //   //'verifyFp': verifyFp,
//     //   //'user_agent': headers['user-agent'],
//     // };
//     // // var uri = Uri.https(mainHost, '/web/search/topsearch/', queryParameters);

//     // http.Response response = await http.get(uri, headers: igHeaders.toJson());

//     // return response;
//   }
// }

// //https://i.instagram.com/api/v1/feed/timeline
