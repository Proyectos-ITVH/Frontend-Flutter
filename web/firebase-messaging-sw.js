importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');


firebase.initializeApp({
apiKey: "AIzaSyDbRSVmx36ra_qPlPw-_O1vJjw_zFX15C0",
authDomain: "iot-calidad-agua-3165b.firebaseapp.com",
projectId: "iot-calidad-agua-3165b",
storageBucket: "iot-calidad-agua-3165b.firebasestorage.app",
messagingSenderId: "132951764258",
appId: "1:132951764258:web:0f93484fa6d1061bb3897b"
});


const messaging = firebase.messaging();


messaging.onBackgroundMessage(function (payload) {
console.log('[firebase-messaging-sw.js] Background message ', payload);


const notificationTitle = payload.notification?.title || 'Notificación';
const notificationOptions = {
body: payload.notification?.body || '',
icon: '/icons/Icon-192.png',
};


self.registration.showNotification(
notificationTitle,
notificationOptions
);
});