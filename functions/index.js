const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotificationOnTransaction = functions.firestore
    .document("expenses/{expenseId}")
    .onCreate(async (snapshot, context) => {
      const data = snapshot.data();
      const category = data.category || "general";
      const amount = data.amount;
      const type = data.type;
      const description = data.description;

      const payload = {
        notification: {
          title: `New ${type.toUpperCase()}: ₹${amount}`,
          body: `${description} (${category})`,
          sound: "default",
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      // Notify everyone subscribed to this category
      return admin.messaging().sendToTopic(category, payload);
    });
