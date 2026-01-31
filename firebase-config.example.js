import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAJA7TreW6Z_Gu4JbgvDhxJtHKie3GwKtg",
  authDomain: "studio-6309792933-aa267.firebaseapp.com",
  projectId: "studio-6309792933-aa267",
  storageBucket: "studio-6309792933-aa267.firebasestorage.app",
  messagingSenderId: "215226220747",
  appId: "1:215226220747:web:6b2c836ecc401ffea25b4e"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

export { app, db, auth, firebaseConfig };
