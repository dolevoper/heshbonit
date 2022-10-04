// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-app.js";
import { getFirestore, collection, doc, getDocs, setDoc } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-firestore.js";
import { getAuth, onAuthStateChanged, GoogleAuthProvider, signInWithRedirect, getRedirectResult, signOut as _signOut } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-auth.js";
import { getStorage, ref, getDownloadURL } from "https://www.gstatic.com/firebasejs/9.10.0/firebase-storage.js";

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
const uid = window.location.pathname.split("/")[1];

const auth = getAuth();
const signOut = () => _signOut(auth).then(() => login({ prompt: "select_account" }));

const db = getFirestore(app);
const invoices = uid && collection(db, "users", uid, "invoices");

const storage = getStorage(app, "gs://heshbonit-invoices");

export { app, getDocs, signOut, doc, setDoc, invoices, downloadInvoice };

async function login(customParameters) {
    const res = await getRedirectResult(auth);
    
    if (!res) {
        const authProvider  = new GoogleAuthProvider();

        authProvider.setCustomParameters(customParameters)
        
        await signInWithRedirect(auth, authProvider);
    }
}

const unsubscribe = onAuthStateChanged(auth, async user => {
    unsubscribe();

    if (!user) {
        await login();
    } else if (window.location.pathname === "/") {
        window.location.assign(user.uid);
    }
});


async function downloadInvoice(invoiceId) {
    const downloadUrl = await getDownloadURL(ref(storage, `${uid}/${invoiceId}.pdf`));

    window.open(downloadUrl, "_blank");
}
