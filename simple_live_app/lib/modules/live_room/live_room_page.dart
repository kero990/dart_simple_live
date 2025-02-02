import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/modules/live_room/live_room_controller.dart';
import 'package:simple_live_app/modules/live_room/player/player_controls.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/superchat_card.dart';
import 'package:simple_live_core/simple_live_core.dart';

class LiveRoomPage extends GetView<LiveRoomController> {
  const LiveRoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.fullScreenState.value) {
          return WillPopScope(
            onWillPop: () async {
              controller.exitFull();
              return false;
            },
            child: Scaffold(
              body: buildMediaPlayer(),
            ),
          );
        } else {
          return buildPageUI();
        }
      },
    );
  }

  Widget buildPageUI() {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: Obx(
              () => Text(controller.detail.value?.title ?? "直播间"),
            ),
            actions: buildAppbarActions(context),
          ),
          body: orientation == Orientation.portrait
              ? buildPhoneUI(context)
              : buildTabletUI(context),
        );
      },
    );
  }

  Widget buildPhoneUI(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: buildMediaPlayer(),
        ),
        buildUserProfile(context),
        buildMessageArea(),
        buildBottomActions(context),
      ],
    );
  }

  Widget buildTabletUI(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: buildMediaPlayer(),
              ),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    buildUserProfile(context),
                    buildMessageArea(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(.1),
              ),
            ),
          ),
          padding: AppStyle.edgeInsetsV4.copyWith(
            bottom: AppStyle.bottomBarHeight + 4,
          ),
          child: Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.refreshRoom,
                icon: const Icon(Remix.refresh_line),
                label: const Text("刷新"),
              ),
              Obx(
                () => controller.followed.value
                    ? TextButton.icon(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: controller.removeFollowUser,
                        icon: const Icon(Remix.heart_fill),
                        label: const Text("取消关注"),
                      )
                    : TextButton.icon(
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        onPressed: controller.followUser,
                        icon: const Icon(Remix.heart_line),
                        label: const Text("关注"),
                      ),
              ),
              const Expanded(child: Center()),
              TextButton.icon(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: controller.share,
                icon: const Icon(Remix.share_line),
                label: const Text("分享"),
              ),
            ],
          ),
        ),
        //buildBottomActions(context),
      ],
    );
  }

  Widget buildMediaPlayer() {
    return Stack(
      children: [
        Obx(() {
          var boxFit = BoxFit.contain;
          double? aspectRatio;
          if (AppSettingsController.instance.scaleMode.value == 0) {
            boxFit = BoxFit.contain;
          } else if (AppSettingsController.instance.scaleMode.value == 1) {
            boxFit = BoxFit.fill;
          } else if (AppSettingsController.instance.scaleMode.value == 2) {
            boxFit = BoxFit.cover;
          } else if (AppSettingsController.instance.scaleMode.value == 3) {
            boxFit = BoxFit.contain;
            aspectRatio = 16 / 9;
          } else if (AppSettingsController.instance.scaleMode.value == 4) {
            boxFit = BoxFit.contain;
            aspectRatio = 4 / 3;
          }
          return Video(
            controller: controller.videoController,
            pauseUponEnteringBackgroundMode: false,
            controls: (state) {
              return playerControls(state, controller);
            },
            aspectRatio: aspectRatio,
            fit: boxFit,
          );
        }),
        Obx(
          () => Visibility(
            visible: !controller.liveStatus.value,
            child: Container(
              color: Colors.black.withOpacity(.5),
              child: const Center(
                child: Text(
                  "未开播",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildUserProfile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(.1),
          ),
          bottom: BorderSide(
            color: Colors.grey.withOpacity(.1),
          ),
        ),
      ),
      padding: AppStyle.edgeInsetsA8.copyWith(
        left: 12,
        right: 12,
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(.2)),
                borderRadius: AppStyle.radius24,
              ),
              child: NetImage(
                controller.detail.value?.userAvatar ?? "",
                width: 48,
                height: 48,
                borderRadius: 24,
              ),
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.detail.value?.userName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Row(
                    children: [
                      Image.asset(
                        controller.site.logo,
                        width: 20,
                      ),
                      AppStyle.hGap4,
                      Text(
                        controller.site.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppStyle.hGap12,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Remix.fire_fill,
                  size: 20,
                  color: Colors.orange,
                ),
                AppStyle.hGap4,
                Text(
                  Utils.onlineToString(
                    controller.detail.value?.online ?? 0,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(.1),
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: AppStyle.bottomBarHeight),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => controller.followed.value
                  ? TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.removeFollowUser,
                      icon: const Icon(Remix.heart_fill),
                      label: const Text("取消关注"),
                    )
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      onPressed: controller.followUser,
                      icon: const Icon(Remix.heart_line),
                      label: const Text("关注"),
                    ),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.refreshRoom,
              icon: const Icon(Remix.refresh_line),
              label: const Text("刷新"),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: controller.share,
              icon: const Icon(Remix.share_line),
              label: const Text("分享"),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageArea() {
    return Expanded(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              indicatorWeight: 1.0,
              tabs: [
                const Tab(
                  text: "聊天",
                ),
                Tab(
                  child: Obx(
                    () => Text(
                      controller.superChats.isNotEmpty
                          ? "醒目留言(${controller.superChats.length})"
                          : "醒目留言",
                    ),
                  ),
                ),
                const Tab(
                  text: "设置",
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Obx(
                    () => ListView.builder(
                      controller: controller.scrollController,
                      padding: AppStyle.edgeInsetsA12,
                      itemCount: controller.messages.length,
                      itemBuilder: (_, i) {
                        var item = controller.messages[i];
                        return buildMessageItem(item);
                      },
                    ),
                  ),
                  buildSuperChats(),
                  buildSettings(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessageItem(LiveMessage message) {
    if (message.userName == "LiveSysMessage") {
      return Obx(
        () => Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSettingsController.instance.chatTextGap.value,
          ),
          child: Text(
            message.message,
            style: TextStyle(
              color: Colors.grey,
              fontSize: AppSettingsController.instance.chatTextSize.value,
            ),
          ),
        ),
      );
    }
    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSettingsController.instance.chatTextGap.value,
        ),
        child: Text.rich(
          TextSpan(
            text: "${message.userName}：",
            style: TextStyle(
              color: Colors.grey,
              fontSize: AppSettingsController.instance.chatTextSize.value,
            ),
            children: [
              TextSpan(
                text: message.message,
                style: TextStyle(
                  color: Get.isDarkMode ? Colors.white : AppColors.black333,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSuperChats() {
    return KeepAliveWrapper(
      child: Obx(
        () => ListView.separated(
          padding: AppStyle.edgeInsetsA12,
          itemCount: controller.superChats.length,
          separatorBuilder: (_, i) => AppStyle.vGap12,
          itemBuilder: (_, i) {
            var item = controller.superChats[i];
            return SuperChatCard(
              item,
              onExpire: () {
                controller.removeSuperChats();
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildSettings() {
    return Obx(
      () => ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          Obx(
            () => Visibility(
              visible: controller.autoExitEnable.value,
              child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text("${controller.countdown.value}秒后自动关闭"),
              ),
            ),
          ),
          Padding(
            padding: AppStyle.edgeInsetsH12.copyWith(top: 12),
            child: Text(
              "聊天区文字大小: ${(AppSettingsController.instance.chatTextSize.value).toInt()}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Slider(
            value: AppSettingsController.instance.chatTextSize.value,
            min: 8,
            max: 36,
            onChanged: (e) {
              AppSettingsController.instance.setChatTextSize(e);
            },
          ),
          Padding(
            padding: AppStyle.edgeInsetsH12.copyWith(top: 12),
            child: Text(
              "聊天区上下间隔: ${(AppSettingsController.instance.chatTextGap.value).toInt()}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Slider(
            value: AppSettingsController.instance.chatTextGap.value,
            min: 0,
            max: 12,
            onChanged: (e) {
              AppSettingsController.instance.setChatTextGap(e);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> buildAppbarActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          showMore();
        },
        icon: const Icon(Icons.more_horiz),
      ),
    ];
  }

  void showMore() {
    showModalBottomSheet(
      context: Get.context!,
      constraints: const BoxConstraints(
        maxWidth: 600,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: AppStyle.bottomBarHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text("刷新"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.refreshRoom();
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              trailing: const Icon(Icons.chevron_right),
              title: const Text("切换清晰度"),
              onTap: () {
                Get.back();
                controller.showQualitySheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_video_outlined),
              title: const Text("切换线路"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showPlayUrlsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio_outlined),
              title: const Text("画面尺寸"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showPlayerSettingsSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("截图"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                controller.saveScreenshot();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text("定时关闭"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.showAutoExitSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_sharp),
              title: const Text("分享链接"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.share();
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text("APP中打开"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.back();
                controller.openNaviteAPP();
              },
            ),
          ],
        ),
      ),
    );
  }
}
