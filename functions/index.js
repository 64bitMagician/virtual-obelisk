const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

// This runs automatically every day at midnight (UTC time)
exports.dailyPointDecay = onSchedule("every day 00:00", async (event) => {
  const db = admin.firestore();
  
  //  Fetch ALL users
  const usersSnapshot = await db.collection("users").get();
  

  const batches = [];
  let currentBatch = db.batch();
  let operationCounter = 0;

  usersSnapshot.forEach((doc) => {
      const userRef = db.collection("users").doc(doc.id);
      const userData = doc.data();

      // Default to 0 if the field doesn't exist yet
      const currentPoints = userData.artist_points || 0;

      // Skip this user entirely if they are already at 0 (Saves database writes/money)
      if (currentPoints > 0) {

        // Calculate the exact deduction to prevent dropping below zero
        let deduction = -100;

        // if bellow 100 points, deduction will be just the right ammount to hit 0 artist points
        if (currentPoints < 100) {
          deduction = -currentPoints;
        }

        // Queue up the safe deduction
        currentBatch.update(userRef, {
          artist_points: admin.firestore.FieldValue.increment(deduction)
        });

        operationCounter++;

        // If we hit the 500 limit, store the batch and start a new one
        if (operationCounter === 490) {
          batches.push(currentBatch);
          currentBatch = db.batch();
          operationCounter = 0;
        }
      }
    });
  
  // Add the final batch to the list
  if (operationCounter > 0) {
    batches.push(currentBatch);
  }

  // Execute all the deductions at once
  for (const batch of batches) {
    await batch.commit();
  }
  
  console.log("Daily point decay completed successfully!");
});