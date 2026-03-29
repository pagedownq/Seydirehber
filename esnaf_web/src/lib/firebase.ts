import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  projectId: "seydirehber1",
  appId: "1:619370654049:web:903b4d94e1343ca96bfd20",
  storageBucket: "seydirehber1.firebasestorage.app",
  apiKey: "AIzaSyDZcRhiWfvke9bPPxL1HfvLroak0VwTZ10",
  authDomain: "seydirehber1.firebaseapp.com",
  messagingSenderId: "619370654049",
  measurementId: "G-KHTWXW3D9T"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
