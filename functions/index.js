const functions = require('firebase-functions');
const admin = require('firebase-admin');
const AccessToken = require('twilio').jwt.AccessToken;
const VideoGrant = AccessToken.VideoGrant;
const utf8 = require('utf8')
// Used when generating any kind of Access Token
const twilioAccountSid = 'ACa3dbfe88730bb3850eb4e5d476d65908';
const twilioApiKey = 'SKdfd4d70edde84e54ada647cc4c63f904';
const twilioApiSecret = '1z9TwLAihKUH5Gm4B6953bITeR1qyIZw';

//Translation
'use strict';
const request = require('request-promise');
var callerOrReceiver = ''

// Create an access token which we will sign and return to the client,
// containing the grant we just created
const token = new AccessToken(twilioAccountSid, twilioApiKey, twilioApiSecret);
admin.initializeApp(functions.config().firebase);

exports.callerToken = functions.database.ref('/connections/{roomUid}/callerUid').onWrite( event => {
  // We'll handle all the logic here
  const roomUid = event.params.roomUid;
  console.log('roomUid');
  console.log(roomUid);

  var callerUid = event.data.toJSON();
  console.log('callerUid');
  console.log(callerUid);

  token.identity = callerUid;

  // Create a Video grant which enables a client to use Video
  // and limits access to the specified Room
  const videoGrant = new VideoGrant({
      room: roomUid
  });

  // Add the grant to the token
  token.addGrant(videoGrant);

  // Serialize the token to a JWT string
  const JwtToken = token.toJwt();
  console.log('JwtToken');
  console.log(JwtToken);
  event.data.adminRef.root.child('tokenCreator').child(roomUid).child('callerToken').set(JwtToken);
  return;
  });

exports.receiverToken = functions.database.ref('/connections/{roomUid}/receiverUid').onWrite( event => {
  // We'll handle all the logic here
  const roomUid = event.params.roomUid;
  console.log('roomUid');
  console.log(roomUid);

  var recipientUid = event.data.toJSON();
  console.log('recipientUid');
  console.log(recipientUid);

  token.identity = recipientUid;

  // Create a Video grant which enables a client to use Video
  // and limits access to the specified Room
  const videoGrant = new VideoGrant({
      room: roomUid
  });

  // Add the grant to the token
  token.addGrant(videoGrant);

  // Serialize the token to a JWT string
  const JwtToken = token.toJwt();
  console.log('JwtToken');
  console.log(JwtToken);
  event.data.adminRef.root.child('tokenCreator').child(roomUid).child('recipientToken').set(JwtToken);
  return;
  });

exports.callerTranslate = functions.database.ref('/connections/{roomUid}/transcription/callerDidTalk/callerLanguage/{callerLanguage}/receiverLanguage/{receiverLanguage}/text/{callerLanguageTwo}').onWrite(event => {
    const snapshot = event.data;
    var room = event.params.roomUid;
    callerOrReceiver = 'receiver';

    var fromLanguage = event.params.callerLanguage;
    var toLanguage = event.params.receiverLanguage;
    var room = event.params.roomUid

    const promises = [];
    const message = snapshot.val();
    message.toString()
    message.replace(/ /g, "+")
    console.log('message:')
    console.log(message)

    const encodedSnap = utf8.encode(message);
    console.log('encoded snapshot');
    console.log(encodedSnap);

    if (fromLanguage == toLanguage) {
        console.log('no translation required');
        return admin.database().ref(`/connections/${room}/transcription/callerDidTalk/callerLanguage/${fromLanguage}/receiverLanguage/${toLanguage}/translated/${toLanguage}`).set(encodedSnap);
    } else {
        console.log('promises.push(createTranslationPromise)');
        promises.push(createTranslationPromise(fromLanguage, toLanguage, encodedSnap, room, callerOrReceiver));
        console.log('Promise.all(promises)');
        console.log(Promise.all(promises));
        return Promise.all(promises);
    }
});

exports.receiverTranslate = functions.database.ref('/connections/{roomUid}/transcription/receiverDidTalk/receiverLanguage/{receiverLanguage}/callerLanguage/{callerLanguage}/text/{receiverLanguageTwo}').onWrite(event => {
    const snapshot = event.data;
    var room = event.params.roomUid;
    callerOrReceiver = 'caller';

    var fromLanguage = event.params.receiverLanguage;
    var toLanguage = event.params.callerLanguage;

    const promises = [];
    const message = snapshot.val();
    message.toString()
    message.replace(/ /g, "+")
    console.log('message:')
    console.log(message)

    const encodedSnap = utf8.encode(message);
    console.log('encoded snapshot');
    console.log(encodedSnap);

    if (fromLanguage == toLanguage) {
        console.log('no translation required');
        return admin.database().ref(`/connections/${room}/transcription/receiverDidTalk/receiverLanguage/${fromLanguage}/callerLanguage/${toLanguage}/translated/${toLanguage}`).set(encodedSnap);
    } else {
        console.log('promises.push(createTranslationPromise)');
        promises.push(createTranslationPromise(fromLanguage, toLanguage, encodedSnap, room, callerOrReceiver));        console.log('Promise.all(promises)');
        console.log(Promise.all(promises));
        return Promise.all(promises);
    }
});

// URL to the Google Translate API.
function createTranslateUrl(source, target, payload) {
  return `https://www.googleapis.com/language/translate/v2?key=${functions.config().firebase.apiKey}&source=${source}&target=${target}&q=${payload}`;
}

function createTranslationPromise(source, target, encodedSnap, room, callerOrReceiver) {
  return request(createTranslateUrl(source, target, encodedSnap), {resolveWithFullResponse: true}).then(
      response => {
        var sourceString = `${source}`
        var targetString = `${target}`
        console.log(sourceString)
        console.log(targetString)
        console.log(encodedSnap);
        if (response.statusCode === 200) {
            if (callerOrReceiver === 'caller') {
                const data = JSON.parse(response.body).data;
                console.log(data.translations[0].translatedText);
                return admin.database().ref(`/connections/${room}/transcription/receiverDidTalk/receiverLanguage/${sourceString}/callerLanguage/${targetString}/translated/${targetString}`).set(data.translations[0].translatedText);
            } if (callerOrReceiver === 'receiver') {
                const data = JSON.parse(response.body).data;
                console.log(data.translations[0].translatedText);
                return admin.database().ref(`/connections/${room}/transcription/callerDidTalk/callerLanguage/${sourceString}/receiverLanguage/${targetString}/translated/${targetString}`).set(data.translations[0].translatedText);
            }
        }
        throw response.body;
      });
}












// const functions = require('firebase-functions');
// const admin = require('firebase-admin');
// const AccessToken = require('twilio').jwt.AccessToken;
// const VideoGrant = AccessToken.VideoGrant;
// const utf8 = require('utf8')
// // Used when generating any kind of Access Token
// const twilioAccountSid = 'ACa3dbfe88730bb3850eb4e5d476d65908';
// const twilioApiKey = 'SKdfd4d70edde84e54ada647cc4c63f904';
// const twilioApiSecret = '1z9TwLAihKUH5Gm4B6953bITeR1qyIZw';
//
// //Translation
// 'use strict';
// const request = require('request-promise');
// var callerOrReceiver = ''
//
// //admin.initializeApp(functions.config().firebase);
//
// //var db = admin.database();
// // List of output languages.
// //const LANGUAGES = ['en', 'es', 'de', 'fr', 'sv', 'ga', 'it', 'jp'];
//
// // Create an access token which we will sign and return to the client,
// // containing the grant we just created
// const token = new AccessToken(twilioAccountSid, twilioApiKey, twilioApiSecret);
// admin.initializeApp(functions.config().firebase);
//
// exports.callerToken = functions.database.ref('/connections/{roomUid}/callerUid').onWrite( event => {
//   // We'll handle all the logic here
//   const roomUid = event.params.roomUid;
//   console.log('roomUid');
//   console.log(roomUid);
//
//   var callerUid = event.data.toJSON();
//   console.log('callerUid');
//   console.log(callerUid);
//
//   token.identity = callerUid;
//
//   // Create a Video grant which enables a client to use Video
//   // and limits access to the specified Room
//   const videoGrant = new VideoGrant({
//       room: roomUid
//   });
//
//   // Add the grant to the token
//   token.addGrant(videoGrant);
//
//   // Serialize the token to a JWT string
//   const JwtToken = token.toJwt();
//   console.log('JwtToken');
//   console.log(JwtToken);
//   event.data.adminRef.root.child('tokenCreator').child(roomUid).child('callerToken').set(JwtToken);
//   return;
//   });
//
// exports.receiverToken = functions.database.ref('/connections/{roomUid}/receiverUid').onWrite( event => {
//   // We'll handle all the logic here
//   const roomUid = event.params.roomUid;
//   console.log('roomUid');
//   console.log(roomUid);
//
//   var recipientUid = event.data.toJSON();
//   console.log('recipientUid');
//   console.log(recipientUid);
//
//   token.identity = recipientUid;
//
//   // Create a Video grant which enables a client to use Video
//   // and limits access to the specified Room
//   const videoGrant = new VideoGrant({
//       room: roomUid
//   });
//
//   // Add the grant to the token
//   token.addGrant(videoGrant);
//
//   // Serialize the token to a JWT string
//   const JwtToken = token.toJwt();
//   console.log('JwtToken');
//   console.log(JwtToken);
//   event.data.adminRef.root.child('tokenCreator').child(roomUid).child('recipientToken').set(JwtToken);
//   return;
//   });
//
// exports.callerTranslate = functions.database.ref('/connections/{roomUid}/transcription/callerDidTalk/callerLanguage/{callerLanguage}/receiverLanguage/{receiverLanguage}/text/{callerLanguageTwo}').onWrite(event => {
//
//
//     const snapshot = event.data;
//     //var text = event.params.text;
//     var fromLanguage = event.params.callerLanguage;
//     //to listeners language
//     var toLanguage = event.params.receiverLanguage;
//     const promises = [];
//
//     console.log('snapshot');
//     console.log(snapshot);
//
//     const encodedString = utf8.encode(snapshot);
//     console.log('encoded snapshot');
//     console.log(encodedString);
//
//     var room = event.params.roomUid;
//     callerOrReceiver = 'receiver';
//
//     console.log('promises.push(createTranslationPromise)');
//     promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot, room, callerOrReceiver));
//     console.log('Promise.all(promises)');
//     console.log(Promise.all(promises));
//     return Promise.all(promises);
//   //var ref = db.ref("server/saving-data/fireblog/posts");
//   //var ref = functions.database
// /*
//   var receiverLanguageRef = functions.database.ref('connections').child(room).child('transcription/receiverDidTalk/receiverLanguage')
//   // Attach an asynchronous callback to read the data at our posts reference
//   ref.on("value", function(snapshot) {
//       console.log(snapshot);
//       console.log(snapshot.val());
//   }, function (errorObject) {
//       console.log("The read failed: " + errorObject.code);
//   });*/
//
//
//
//
//   // const promises = [];
//   // for (let i = 0; i < LANGUAGES.length; i++) {
//   //   var language = LANGUAGES[i];
//   //   if (language !== event.params.languageID) {
//   //     promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot));
//   //   }
//   // }
//   // return Promise.all(promises);
// });
//
// exports.receiverTranslate = functions.database.ref('/connections/{roomUid}/transcription/receiverDidTalk/receiverLanguage/{receiverLanguage}/callerLanguage/{callerLanguage}/text/{receiverLanguageTwo}').onWrite(event => {
//   const snapshot = event.data;
//   //var text = event.params.text;
//   var fromLanguage = event.params.receiverLanguage;
//   //to listeners language
//   var toLanguage = event.params.callerLanguage;
//   const promises = [];
//
//   var room = event.params.roomUid;
//   callerOrReceiver = 'caller';
//
//   console.log('createTranslationPromise')
//   console.log('fromLanguage: ')
//   console.log(fromLanguage)
//   console.log('toLanguage: ')
//   console.log(toLanguage)
//   console.log('snapshot: ')
//   console.log(snapshot)
//   console.log('room: ')
//   console.log(room)
//   console.log('callerOrReceiver: ')
//   console.log(callerOrReceiver)
//   promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot, room, callerOrReceiver));
//   console.log('Promise.all(promises): ');
//   console.log(Promise.all(promises));
//   return Promise.all(promises);
//
//
//   // const promises = [];
//   // for (let i = 0; i < LANGUAGES.length; i++) {
//   //   var language = LANGUAGES[i];
//   //   if (language !== event.params.languageID) {
//   //     promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot));
//   //   }
//   // }
//   // return Promise.all(promises);
// });
//
// // URL to the Google Translate API.
// function createTranslateUrl(source, target, payload) {
//   return `https://www.googleapis.com/language/translate/v2?key=${functions.config().firebase.apiKey}&source=${source}&target=${target}&q=${payload}`;
// }
//
// function createTranslationPromise(source, target, snapshot, room, callerOrReceiver) {
//   const key = snapshot.key;
//   const message = snapshot.val();
//   message.toString()
//   //var messageRe = new RegExp(message, "g");
//   message.replace(/ /g, "+")
//   console.log('message:')
//   console.log(message)
//
//
//   //const room = room
//   return request(createTranslateUrl(source, target, message), {resolveWithFullResponse: true}).then(
//       response => {
//         var sourceString = `${source}`
//         var targetString = `${target}`
//         console.log(sourceString)
//         console.log(targetString)
//         console.log(message);
//         if (response.statusCode === 200) {
//             if (callerOrReceiver === 'caller') {
//                 const data = JSON.parse(response.body).data;
//                 //return admin.database().ref(`/connections/${room}/translation/callerDidTalk`).set(data.translations[0].translatedText);
//                 // console.log(sourceString)
//                 // console.log(targetString)
//                 // console.log(message);
//                 console.log(data.translations[0].translatedText);
//                 return admin.database().ref(`/connections/${room}/transcription/receiverDidTalk/receiverLanguage/${sourceString}/callerLanguage/${targetString}/translated/${targetString}`).set(data.translations[0].translatedText);
//
//                 //return ""
//             } if (callerOrReceiver === 'receiver') {
//                 const data = JSON.parse(response.body).data;
//                 //return admin.database().ref(`/connections/${room}/translation/receiverDidTalk`).set(data.translations[0].translatedText);
//                 // console.log(sourceString)
//                 // console.log(targetString)
//                 // console.log(message);
//                 console.log(data.translations[0].translatedText);
//                 return admin.database().ref(`/connections/${room}/transcription/callerDidTalk/callerLanguage/${sourceString}/receiverLanguage/${targetString}/translated/${targetString}`).set(data.translations[0].translatedText);
//
//                 //return ""
//             }
//
//         }
//         throw response.body;
//         // if (response.statusCode === 200) {
//         //   const data = JSON.parse(response.body).data;
//         //   return admin.database().ref(`/messages/${target}/${key}`)
//         //       .set({message: data.translations[0].translatedText, translated: true});
//         // }
//         // throw response.body;
//       });
// }




/*
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const AccessToken = require('twilio').jwt.AccessToken;
const VideoGrant = AccessToken.VideoGrant;
// Used when generating any kind of Access Token
const twilioAccountSid = 'ACa3dbfe88730bb3850eb4e5d476d65908';
const twilioApiKey = 'SKdfd4d70edde84e54ada647cc4c63f904';
const twilioApiSecret = '1z9TwLAihKUH5Gm4B6953bITeR1qyIZw';

//Translation
'use strict';
const request = require('request-promise');
var callerOrReceiver = ''
// List of output languages.
//const LANGUAGES = ['en', 'es', 'de', 'fr', 'sv', 'ga', 'it', 'jp'];

// Create an access token which we will sign and return to the client,
// containing the grant we just created
const token = new AccessToken(twilioAccountSid, twilioApiKey, twilioApiSecret);
admin.initializeApp(functions.config().firebase);

exports.callerToken = functions.database.ref('/connections/{roomUid}/callerUid').onWrite( event => {
  // We'll handle all the logic here
  const roomUid = event.params.roomUid;
  console.log('roomUid');
  console.log(roomUid);

  var callerUid = event.data.toJSON();
  console.log('callerUid');
  console.log(callerUid);

  token.identity = callerUid;

  // Create a Video grant which enables a client to use Video
  // and limits access to the specified Room
  const videoGrant = new VideoGrant({
      room: roomUid
  });

  // Add the grant to the token
  token.addGrant(videoGrant);

  // Serialize the token to a JWT string
  const JwtToken = token.toJwt();
  console.log('JwtToken');
  console.log(JwtToken);
  event.data.adminRef.root.child('tokenCreator').child(roomUid).child('callerToken').set(JwtToken);
  return;
  });

exports.receiverToken = functions.database.ref('/connections/{roomUid}/receiverUid').onWrite( event => {
  // We'll handle all the logic here
  const roomUid = event.params.roomUid;
  console.log('roomUid');
  console.log(roomUid);

  var recipientUid = event.data.toJSON();
  console.log('recipientUid');
  console.log(recipientUid);

  token.identity = recipientUid;

  // Create a Video grant which enables a client to use Video
  // and limits access to the specified Room
  const videoGrant = new VideoGrant({
      room: roomUid
  });

  // Add the grant to the token
  token.addGrant(videoGrant);

  // Serialize the token to a JWT string
  const JwtToken = token.toJwt();
  console.log('JwtToken');
  console.log(JwtToken);
  event.data.adminRef.root.child('tokenCreator').child(roomUid).child('recipientToken').set(JwtToken);
  return;
  });

exports.callerTranslate = functions.database.ref('/connections/{roomUid}/transcription/callerDidTalk/callerLanguage/{languageID}').onWrite(event => {
  const snapshot = event.data;
  //var text = event.params.text;
  var fromLanguage = event.params.languageID;
  //to listeners language
  var toLanguage = "en";
  const promises = [];

  var room = event.params.roomUid;
  callerOrReceiver = 'caller';

  console.log('snapshot');
  console.log(snapshot);



  var ref = db.ref("server/saving-data/fireblog/posts");

  var receiverLanguageRef = db.ref('connections').child(room).child('transcription/receiverDidTalk/receiverLanguage')
  // Attach an asynchronous callback to read the data at our posts reference
  ref.on("value", function(snapshot) {
      console.log(snapshot.val());
  }, function (errorObject) {
      console.log("The read failed: " + errorObject.code);
  });

  promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot, room, callerOrReceiver));
  return Promise.all(promises);


  // const promises = [];
  // for (let i = 0; i < LANGUAGES.length; i++) {
  //   var language = LANGUAGES[i];
  //   if (language !== event.params.languageID) {
  //     promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot));
  //   }
  // }
  // return Promise.all(promises);
});

exports.receiverTranslate = functions.database.ref('/connections/{roomUid}/transcription/receiverDidTalk/receiverLanguage/{languageID}').onWrite(event => {
  const snapshot = event.data;
  //var text = event.params.text;
  var fromLanguage = event.params.languageID;
  //to listeners language
  var toLanguage = "en";
  const promises = [];

  var room = event.params.roomUid;
  callerOrReceiver = 'receiver';

  console.log('snapshot');
  console.log(snapshot);

  promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot, room, callerOrReceiver));
  return Promise.all(promises);


  // const promises = [];
  // for (let i = 0; i < LANGUAGES.length; i++) {
  //   var language = LANGUAGES[i];
  //   if (language !== event.params.languageID) {
  //     promises.push(createTranslationPromise(fromLanguage, toLanguage, snapshot));
  //   }
  // }
  // return Promise.all(promises);
});

// URL to the Google Translate API.
function createTranslateUrl(source, target, payload) {
  return `https://www.googleapis.com/language/translate/v2?key=${functions.config().firebase.apiKey}&source=${source}&target=${target}&q=${payload}`;
}

function createTranslationPromise(source, target, snapshot, room, callerOrReceiver) {
  const key = snapshot.key;
  const message = snapshot.val();
  console.log('key');
  console.log(key);
  console.log('message');
  console.log(message);
  //const room = room
  return request(createTranslateUrl(source, target, message), {resolveWithFullResponse: true}).then(
      response => {
        var targetString = `${target}`
        if (response.statusCode === 200) {
            if (callerOrReceiver === 'caller') {
                const data = JSON.parse(response.body).data;
                //return admin.database().ref(`/connections/${room}/translation/callerDidTalk`).set(data.translations[0].translatedText);
                return admin.database().ref(`/connections/${room}/transcription/callerDidTalk/${targetString}`).set(data.translations[0].translatedText);                //return admin.database().ref(`/connections/${target}/${key}`)
                    //.set({message: data.translations[0].translatedText, translated: true});
            } if (callerOrReceiver === 'receiver') {
                const data = JSON.parse(response.body).data;
                //return admin.database().ref(`/connections/${room}/translation/receiverDidTalk`).set(data.translations[0].translatedText);
                return admin.database().ref(`/connections/${room}/transcription/receiverDidTalk/${targetString}`).set(data.translations[0].translatedText);
            }

        }
        throw response.body;
        // if (response.statusCode === 200) {
        //   const data = JSON.parse(response.body).data;
        //   return admin.database().ref(`/messages/${target}/${key}`)
        //       .set({message: data.translations[0].translatedText, translated: true});
        // }
        // throw response.body;
      });
}*/





  //
  // const functions = require('firebase-functions');
  // const admin = require('firebase-admin');
  // const AccessToken = require('twilio').jwt.AccessToken;
  // const VideoGrant = AccessToken.VideoGrant;
  //
  // // Used when generating any kind of Access Token
  // const twilioAccountSid = 'ACa3dbfe88730bb3850eb4e5d476d65908';
  // const twilioApiKey = 'SKdfd4d70edde84e54ada647cc4c63f904';
  // const twilioApiSecret = '1z9TwLAihKUH5Gm4B6953bITeR1qyIZw';
  //
  // // Create an access token which we will sign and return to the client,
  // // containing the grant we just created
  // const token = new AccessToken(twilioAccountSid, twilioApiKey, twilioApiSecret);
  // admin.initializeApp(functions.config().firebase);
  //
  // exports.callerToken = functions.database.ref('/connections/{roomUid}/callerUid').onWrite( event => {
  //   // We'll handle all the logic here
  //   //let authUserUid = functions.auth.UserInfo.uid
  //   const roomUid = event.params.roomUid
  //   console.log('roomUid')
  //   console.log(roomUid)
  //
  //   var callerUid = event.data.toJSON();
  //   console.log('callerUid');
  //   console.log(callerUid);
  //
  //   //const uid = Object.keys(jsonVal)[0];
  //   //console.log('jsonVal');
  //   //console.log(jsonVal);
  //
  //   token.identity = callerUid;
  //   //console.log(uid);
  //
  //   // Create a Video grant which enables a client to use Video
  //   // and limits access to the specified Room (DailyStandup)
  //   const videoGrant = new VideoGrant({
  //       room: roomUid
  //   });
  //
  //   // Add the grant to the token
  //   token.addGrant(videoGrant);
  //
  //   // Serialize the token to a JWT string
  //   const JwtToken = token.toJwt();
  //   console.log('JwtToken');
  //   console.log(JwtToken);
  //   event.data.adminRef.root.child('tokenCreator').child(roomUid).child('callerToken').set(JwtToken);
  //   //functions.database.ref.child('callAttempts').child(recipientUid).child('callerToken').set(JwtToken);
  //   return;
  //   });
  //
  // exports.receiverToken = functions.database.ref('/connections/{roomUid}/receiverUid').onWrite( event => {
  //   // We'll handle all the logic here
  //   //let authUserUid = functions.auth.UserInfo.uid
  //   const roomUid = event.params.roomUid
  //   console.log('roomUid')
  //   console.log(roomUid)
  //
  //
  //   var recipientUid = event.data.toJSON();
  //   console.log('recipientUid');
  //   console.log(recipientUid);
  //
  //   //const uid = Object.keys(jsonVal)[0];
  //   //console.log('jsonVal');
  //   //console.log(jsonVal);
  //
  //   token.identity = recipientUid;
  //   //console.log(uid);
  //
  //   // Create a Video grant which enables a client to use Video
  //   // and limits access to the specified Room (DailyStandup)
  //   const videoGrant = new VideoGrant({
  //       room: roomUid
  //   });
  //
  //   // Add the grant to the token
  //   token.addGrant(videoGrant);
  //
  //   // Serialize the token to a JWT string
  //   const JwtToken = token.toJwt();
  //   console.log('JwtToken');
  //   console.log(JwtToken);
  //   event.data.adminRef.root.child('tokenCreator').child(roomUid).child('recipientToken').set(JwtToken);
  //   //functions.database.ref.child('callAttempts').child(recipientUid).child('callerToken').set(JwtToken);
  //   return;
  //   });
