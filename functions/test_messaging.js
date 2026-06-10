const admin = require("firebase-admin");
admin.initializeApp({projectId: "test-project"});
const messaging = admin.messaging();

const fcmMessage = {
    topic: "all_users",
    notification: {
        title: "Test",
        body: "Test",
    },
    data: {
        type: "ad",
        relatedId: "123",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
        priority: "high",
        notification: {
            channelId: "sudan_free_channel",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: "@drawable/sudan1",
        },
    },
    apns: {
        payload: {
            aps: {
                alert: {
                    title: "Test",
                    body: "Test",
                },
                badge: 1,
                sound: "default",
            },
        },
    },
};

try {
    // We can't actually send, but maybe we can validate using send(..., dryRun=true)
    messaging.send(fcmMessage, true).then(res => console.log(res)).catch(err => console.error("ERROR:", err.message));
} catch (err) {
    console.error("SYNC ERROR:", err);
}
