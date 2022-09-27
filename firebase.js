// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-app.js";
import { getFirestore, collection, getDocs } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-firestore.js";
import { getAuth, onAuthStateChanged, GoogleAuthProvider, signInWithRedirect, getRedirectResult } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-auth.js";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyD_3WFxbnzRpe4ipbVvHbYS_JkPWyqV26I",
    authDomain: "heshbonit-11b34.firebaseapp.com",
    projectId: "heshbonit-11b34",
    storageBucket: "heshbonit-11b34.appspot.com",
    messagingSenderId: "384193528891",
    appId: "1:384193528891:web:0fb3880bd76381fc82481e"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const auth = getAuth();
const authProvider  = new GoogleAuthProvider();

async function login() {
    const res = await getRedirectResult(auth);

    if (!res) await signInWithRedirect(auth, authProvider);
}

onAuthStateChanged(auth, user => {
    !user && login();
});

export { app, db, collection, getDocs };
