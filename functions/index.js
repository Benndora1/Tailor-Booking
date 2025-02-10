/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
import 'package:cloud_functions/cloud_functions.dart';


exports.syncTailors = functions.firestore
    .document('users/{userId}')
    .onWrite((change, context) => {
      const userId = context.params.userId;
      const data = change.after.data();

      if (!data || data.role !== 'tailor') {
        return admin.firestore()
          .collection('tailors')
          .doc(userId)
          .delete();
      }

      const requiredFields = [
        'location',
        'services',
        'experience',
        'rating',
        'status',
        'name',
        'email'
      ];

      if (requiredFields.every(field => data[field])) {
        return admin.firestore()
          .collection('tailors')
          .doc(userId)
          .set(data);
      }

      console.log(`Missing required fields for tailor ${userId}`);
      return null;
    });

