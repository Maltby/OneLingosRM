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

exports.conversationTranslate = functions.database.ref('/conversations/{conversationUUID}/inputText/{messageCount}/{inputLanguage}/{outputLanguage}/text').onWrite(event => {
    const snapshot = event.data;
    var conversationUUID = event.params.conversationUUID;

    var inputLanguage = event.params.inputLanguage;
    var outputLanguage = event.params.outputLanguage;
    var messageCount = event.params.messageCount;

    const promises = [];
    const text = snapshot.val();
    text.toString()
    text.replace(/ /g, "+")
    console.log('text:')
    console.log(text)

    const encodedSnap = utf8.encode(text);
    console.log('encoded snapshot');
    console.log(encodedSnap);

    if (inputLanguage == outputLanguage) {
        console.log('no translation required');
        return admin.database().ref(`/conversations/${conversationUUID}/outputText/${messageCount}/${outputLanguage}/text`).set(encodedSnap);
    } else {
        console.log('promises.push(createConversationTranslationPromise)');
        promises.push(createConversationTranslationPromise(inputLanguage, outputLanguage, encodedSnap, conversationUUID, messageCount));
        console.log('Promise.all(promises)');
        console.log(Promise.all(promises));
        return Promise.all(promises);
    }
});


exports.pushCallNotificaiton = functions.database.ref('/users/{userUid}/notificationIsPresent').onWrite(event => {
    const snapshot = event.data;
    const text = snapshot.val();
    var userUid = event.params.userUid;

    ref.child("users").child(receiverUid).child("notificationIsPresent").setValue(true)

    if (inputLanguage == outputLanguage) {
        console.log('no translation required');
        return admin.database().ref(`/conversations/${conversationUUID}/outputText/${messageCount}/${outputLanguage}/text`).set(encodedSnap);
    } else {
        console.log('promises.push(createConversationTranslationPromise)');
        promises.push(createConversationTranslationPromise(inputLanguage, outputLanguage, encodedSnap, conversationUUID, messageCount));
        console.log('Promise.all(promises)');
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

function createConversationTranslationPromise(source, target, encodedSnap, conversationUUID, messageCount) {
  return request(createTranslateUrl(source, target, encodedSnap), {resolveWithFullResponse: true}).then(
      response => {
        var sourceString = `${source}`
        var targetString = `${target}`
        console.log(sourceString)
        console.log(targetString)
        console.log(encodedSnap);
        if (response.statusCode === 200) {

            const data = JSON.parse(response.body).data;
            console.log(data.translations[0].translatedText);
            return admin.database().ref(`/conversations/${conversationUUID}/outputText/${messageCount}/${target}/text`).set(data.translations[0].translatedText);
        }
        throw response.body;
      });
}
