import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opole/pages/splash_screen_page/model/fetch_login_user_profile_model.dart';
import 'package:opole/core/services/supabase_client.dart' as local;
import 'package:opole/pages/profile_page/model/profile_models.dart';
import 'package:opole/routes/app_routes.dart';
import 'package:opole/utils/enums.dart';
import 'package:opole/utils/utils.dart';

// ❌ IMPORT OBSOLETO COMENTADO - Módulo preview_shorts_video_page eliminado
// import 'package:opole/pages/preview_shorts_video_page/model/preview_shorts_video_model.dart';

class PreviewUserProfileController extends GetxController with GetTickerProviderStateMixin {
  TabController? tabController;

  FetchProfileModel? fetchProfileModel;
  bool isLoadingProfile = false;
  bool isFollow = false;

  bool isLoadingVideo = true;
  FetchProfileVideoModel? fetchProfileVideoModel;
  List<ProfileVideoData> videoCollection = [];

  bool isLoadingPost = true;
  FetchProfilePostModel? fetchProfilePostModel;
  List<ProfilePostData> postCollection = [];

  bool isLoadingCollection = true;
  FetchProfileCollectionModel? fetchProfileCollectionModel;
  List<ProfileCollectionData> giftCollection = [];

  String userId = "";

  @override
  Future<void> onInit() async {
    tabController = TabController(length: 3, vsync: this);
    tabController?.addListener(onChangeTabBar);
    Utils.showLog("Preview User Profile Controller Initialize");
    if (Get.arguments != null) {
      userId = Get.arguments;
    }
    init();
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    tabController?.removeListener(onChangeTabBar);
    Utils.showLog("Preview User Profile Controller Dispose");
    super.onClose();
  }

  Future<void> init() async {
    isLoadingVideo = true;
    isLoadingPost = true;
    isLoadingCollection = true;

    await onGetProfile(userId: userId);
    await onGetVideo(userId: userId);
  }

  bool isChangingTab = false;

  Future<void> onChangeTabBar() async {
    isChangingTab = true;
    await 400.milliseconds.delay();

    if (isChangingTab) {
      isChangingTab = false;
      if (tabController?.index == 0) {
        Utils.showLog("Tab Change To Reels => ${tabController?.index}");
        if (isLoadingVideo) {
          onGetVideo(userId: userId);
        }
      } else if (tabController?.index == 1) {
        Utils.showLog("Tab Change To Feeds => ${tabController?.index}");
        if (isLoadingPost) {
          onGetPost(userId: userId);
        }
      } else if (tabController?.index == 2) {
        Utils.showLog("Tab Change To Collections => ${tabController?.index}");
        if (isLoadingCollection) {
          onGetCollection(userId: userId);
        }
      }
    }
  }

  Future<void> onGetProfile({required String userId}) async {
    isLoadingProfile = true;
    update(["onGetProfile"]);

    try {
      final currentUserId = local.SupabaseClient.currentUserId;

      final profileData = await local.SupabaseClient.from('profiles')
          .select('id, username, name, avatar, bio, is_verified, followers_count, following_count')
          .eq('id', userId)
          .single();

      bool following = false;
      if (currentUserId != null) {
        final followCheck = await local.SupabaseClient.from('follows')
            .select('id')
            .eq('follower_id', currentUserId)
            .eq('following_id', userId)
            .maybeSingle();
        following = followCheck != null;
      }

      fetchProfileModel = FetchProfileModel(
        userProfileData: UserProfileData(
          user: UserData(
            id: profileData['id'],
            name: profileData['name'] ?? '',
            userName: profileData['username'] ?? '',
            image: profileData['avatar'] ?? '',
            bio: profileData['bio'] ?? '',
            isVerified: profileData['is_verified'] ?? false,
          ),
        ),
      );

      isFollow = following;
    } catch (e, stack) {
      Utils.showLog("❌ Error obteniendo perfil: $e");
      print(stack);
    } finally {
      isLoadingProfile = false;
      update(["onGetProfile"]);
    }
  }

  Future<void> onGetVideo({required String userId}) async {
    isLoadingVideo = true;
    videoCollection.clear();
    update(["onGetVideo"]);

    try {
      final currentUserId = local.SupabaseClient.currentUserId;

      final reelsData = await local.SupabaseClient.from('reels')
          .select('''
            id,
            user_id,
            video_url,
            thumbnail_url,
            caption,
            created_at,
            users!inner(name, username, avatar)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<ProfileVideoData> videos = [];
      for (var reel in reelsData) {
        bool liked = false;
        if (currentUserId != null) {
          final likeCheck = await local.SupabaseClient.from('likes')
              .select('id')
              .eq('reel_id', reel['id'])
              .eq('user_id', currentUserId)
              .maybeSingle();
          liked = likeCheck != null;
        }

        videos.add(ProfileVideoData(
          id: reel['id'],
          userId: reel['user_id'],
          name: reel['users']['name'] ?? '',
          userName: reel['users']['username'] ?? '',
          userImage: reel['users']['avatar'] ?? '',
          videoUrl: reel['video_url'],
          videoImage: reel['thumbnail_url'],
          caption: reel['caption'],
          hashTag: [],
          isLike: liked,
          totalLikes: 0,
          totalComments: 0,
          isBanned: false,
          songId: '',
        ));
      }

      fetchProfileVideoModel = FetchProfileVideoModel(data: videos);
      videoCollection.assignAll(videos);
    } catch (e, stack) {
      Utils.showLog("❌ Error obteniendo videos: $e");
      print(stack);
    } finally {
      isLoadingVideo = false;
      update(["onGetVideo"]);
    }
  }

  Future<void> onGetPost({required String userId}) async {
    isLoadingPost = true;
    postCollection.clear();
    update(["onGetPost"]);

    try {
      final postsData = await local.SupabaseClient.from('posts')
          .select('id, image_url, caption, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<ProfilePostData> posts = postsData.map<ProfilePostData>((post) {
        return ProfilePostData(
          id: post['id'],
          mainPostImage: post['image_url'],
          caption: post['caption'],
        );
      }).toList();

      fetchProfilePostModel = FetchProfilePostModel(data: posts);
      postCollection.assignAll(posts);
    } catch (e, stack) {
      Utils.showLog("❌ Error obteniendo posts: $e");
      print(stack);
    } finally {
      isLoadingPost = false;
      update(["onGetPost"]);
    }
  }

  Future<void> onGetCollection({required String userId}) async {
    isLoadingCollection = true;
    giftCollection.clear();
    update(["onGetCollection"]);

    try {
      final giftsData = await local.SupabaseClient.from('gifts')
          .select('id, image, name, price')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<ProfileCollectionData> gifts = giftsData.map<ProfileCollectionData>((gift) {
        return ProfileCollectionData(
          id: gift['id'],
          giftImage: gift['image'],
          name: gift['name'],
          price: (gift['price'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      fetchProfileCollectionModel = FetchProfileCollectionModel(data: gifts);
      giftCollection.assignAll(gifts);
    } catch (e, stack) {
      Utils.showLog("❌ Error obteniendo colecciones: $e");
      print(stack);
    } finally {
      isLoadingCollection = false;
      update(["onGetCollection"]);
    }
  }

  Future<void> onClickFollow() async {
    final currentUserId = local.SupabaseClient.currentUserId;
    if (currentUserId == null) {
      Utils.showToast("Debes iniciar sesión");
      return;
    }

    if (userId == currentUserId) {
      Utils.showToast(EnumLocal.txtYouCantFollowYourOwnAccount.name.tr);
      return;
    }

    isFollow = !isFollow;
    update(["onClickFollow"]);

    try {
      if (isFollow) {
        await local.SupabaseClient.from('follows').insert({
          'follower_id': currentUserId,
          'following_id': userId,
        });
        await local.SupabaseClient.rpc('increment_followers_count', params: {'user_id': userId});
        await local.SupabaseClient.rpc('increment_following_count', params: {'user_id': currentUserId});
      } else {
        await local.SupabaseClient.from('follows')
            .delete()
            .eq('follower_id', currentUserId)
            .eq('following_id', userId);
        await local.SupabaseClient.rpc('decrement_followers_count', params: {'user_id': userId});
        await local.SupabaseClient.rpc('decrement_following_count', params: {'user_id': currentUserId});
      }
    } catch (e, stack) {
      Utils.showLog("❌ Error en follow/unfollow: $e");
      print(stack);
      isFollow = !isFollow;
      update(["onClickFollow"]);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // SECCIÓN DE SHORTS COMENTADA - Módulo preview_shorts_video_page eliminado
  // La funcionalidad de visualización de reels en pantalla completa
  // ahora se maneja mediante el modo inmersivo (reelsInmersivePage).
  // ─────────────────────────────────────────────────────────────────
  /*
  Future<void> onClickReels(int index) async {
    List<PreviewShortsVideoModel> mainShorts = [];
    for (int i = 0; i < videoCollection.length; i++) {
      final video = videoCollection[i];
      mainShorts.add(
        PreviewShortsVideoModel(
          name: video.name ?? '',
          userId: video.userId ?? '',
          userName: video.userName ?? '',
          userImage: video.userImage ?? '',
          videoId: video.id ?? '',
          videoUrl: video.videoUrl ?? '',
          videoImage: video.videoImage ?? '',
          caption: video.caption ?? '',
          hashTag: video.hashTag ?? [],
          isLike: video.isLike ?? false,
          likes: video.totalLikes ?? 0,
          comments: video.totalComments ?? 0,
          isBanned: video.isBanned ?? false,
          songId: video.songId ?? '',
        ),
      );
    }
    Get.toNamed(AppRoutes.previewShortsVideoPage, arguments: {
      "index": index,
      "video": mainShorts,
      "previousPageIsAudioWiseVideoPage": false
    });
  }
  */

  // 🆕 Método alternativo: navegar al modo inmersivo en lugar de shorts preview
  Future<void> onClickReels(int index) async {
    // Construir lista de videos para el modo inmersivo
    final List<Map<String, dynamic>> immersiveVideos = videoCollection.map((video) {
      return {
        'id': video.id,
        'url': video.videoUrl,
        'thumbnail': video.videoImage,
        'caption': video.caption,
        'userId': video.userId,
        'userName': video.userName,
        'userImage': video.userImage,
        'likes': video.totalLikes,
        'comments': video.totalComments,
        'isLiked': video.isLike,
        'hashTags': video.hashTag,
        'songId': video.songId,
      };
    }).toList();

    Get.toNamed(
      AppRoutes.reelsInmersivePage,
      arguments: {
        'initialIndex': index,
        'videos': immersiveVideos,
        'source': 'profile', // Indica que viene del perfil de usuario
      },
    );
  }
}