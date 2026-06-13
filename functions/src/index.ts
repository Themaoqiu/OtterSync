/**
 * Cloud Functions：把写入 Firestore 的协作通知，通过 FCM 定向推送到收件人设备。
 *
 * 客户端（lib/services/messaging_service.dart）已完成令牌注册与前/后台消息监听，
 * 这里补上服务端的「最后一公里」：监听 notifications 集合新增文档，读取收件人
 * 在 users/{uid}.fcmTokens 里登记的设备令牌，用 Admin SDK 群发推送。
 */

import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();
setGlobalOptions({maxInstances: 10});

const db = getFirestore();

/**
 * 每当 notifications 集合新增一条文档时触发。
 *
 * 文档结构由客户端 _createNotification 写入，关键字段：
 * recipientUid / title / description / workItemId / route。
 */
export const onNotificationCreated = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }
    const data = snapshot.data();
    const recipientUid: string | undefined = data.recipientUid;
    if (!recipientUid) {
      logger.warn("通知缺少 recipientUid，跳过推送", {id: event.params.notificationId});
      return;
    }

    // 取收件人登记的设备令牌。
    const userSnap = await db.collection("users").doc(recipientUid).get();
    const tokens: string[] =
      (userSnap.get("fcmTokens") as string[] | undefined) ?? [];
    if (tokens.length === 0) {
      logger.info("收件人无可用令牌，跳过推送", {recipientUid});
      return;
    }

    const title: string = data.title ?? "OtterSync";
    const body: string = data.description ?? "";
    const route: string | undefined = data.route;
    const workItemId = data.workItemId;

    // route 与 workItemId 放进 data 段，供客户端点击推送后跳转。
    const message = {
      tokens,
      notification: {title, body},
      data: {
        ...(route ? {route: String(route)} : {}),
        ...(workItemId != null ? {workItemId: String(workItemId)} : {}),
      },
      android: {priority: "high" as const},
    };

    const response = await getMessaging().sendEachForMulticast(message);
    logger.info("推送完成", {
      recipientUid,
      success: response.successCount,
      failure: response.failureCount,
    });

    // 清理失效令牌（卸载 / 过期），避免下次重复推给死令牌。
    const stale: string[] = [];
    response.responses.forEach((resp, index) => {
      if (resp.success) {
        return;
      }
      const code = resp.error?.code ?? "";
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        stale.push(tokens[index]);
      }
    });
    if (stale.length > 0) {
      await db.collection("users").doc(recipientUid).update({
        fcmTokens: FieldValue.arrayRemove(...stale),
      });
      logger.info("已清理失效令牌", {recipientUid, removed: stale.length});
    }
  },
);
