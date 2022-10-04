// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-app.js";
import { getFirestore, collection, doc, getDocs, setDoc } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-firestore.js";
import { getAuth, onAuthStateChanged, GoogleAuthProvider, signInWithRedirect, getRedirectResult, signOut as _signOut } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-auth.js";

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

const auth = getAuth();
const signOut = () => _signOut(auth).then(() => login({ prompt: "select_account" }));

const db = getFirestore(app);
const invoicesCollection = collection(db, "invoices");

const getCurrentUser = () => new Promise(resolve => {
    console.log("hello");
    const unsubscribe = onAuthStateChanged(auth, user => {
        unsubscribe();
        resolve(user);
    });
});

const getInvoicesCollection = () => getCurrentUser().then(({ uid }) => collection(db, "users", uid, "invoices"));

export { app, invoicesCollection, getDocs, signOut, doc, setDoc, getInvoicesCollection };

async function login(customParameters) {
    const res = await getRedirectResult(auth);
    
    if (!res) {
        const authProvider  = new GoogleAuthProvider();

        authProvider.setCustomParameters(customParameters)
        
        await signInWithRedirect(auth, authProvider);
    }
}

const unsubscribe = onAuthStateChanged(auth, user => {
    unsubscribe();
    !user && login();
});

