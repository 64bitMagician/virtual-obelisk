const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

exports.dailyPointDecay = onSchedule("every day 00:00", async (event) => {
  const db = admin.firestore();
  
  const usersSnapshot = await db.collection("users").get();
  

  const batches = [];
  let currentBatch = db.batch();
  let operationCounter = 0;

  usersSnapshot.forEach((doc) => {
      const userRef = db.collection("users").doc(doc.id);
      const userData = doc.data();

      const currentPoints = userData.artist_points || 0;

      if (currentPoints > 0) {

        let deduction = -100;

        if (currentPoints < 100) {
          deduction = -currentPoints;
        }

        currentBatch.update(userRef, {
          artist_points: admin.firestore.FieldValue.increment(deduction)
        });

        operationCounter++;

        if (operationCounter === 490) {
          batches.push(currentBatch);
          currentBatch = db.batch();
          operationCounter = 0;
        }
      }
    });
  
  if (operationCounter > 0) {
    batches.push(currentBatch);
  }

  for (const batch of batches) {
    await batch.commit();
  }
  
  console.log("Daily point decay completed successfully!");
});