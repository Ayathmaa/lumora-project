# Lumora Questionnaire & Authentication Flow

This document explains how the newly implemented pre-registration questionnaire interacts with the Lumora authentication system. It ensures that only users with mild to moderate symptoms can create an account, while high-risk users are securely blocked and given emergency resources.

## 1. How Users *Pass* and Create an Account

When a user proves to be within the safe threshold (score < 14, functioning score < 7, and no "Yes" to severe risk questions), the app smoothly routes them to the account creation phase depending on their authentication method:

### A. Standard Email Sign-Up
- The user taps **"Sign Up"** on the Login Screen.
- They are immediately taken to the `QuestionnaireScreen`.
- Once they complete the final page and **pass**, they are navigated directly to the standard `SignupScreen`.
- They can now enter their email, password, and details, officially creating their Firebase account.

### B. Continue as Guest (Anonymous)
- The user taps **"Continue as Guest"**.
- Before Firebase creates the anonymous session, the app suspends the login process and opens the `QuestionnaireScreen`.
- Once they **pass**, the questionnaire returns a success signal (`true`) back to the Login Screen.
- The `signInAnonymously()` function resumes, contacts Firebase to create the guest account, and navigates them to the `AnonymousUsernameScreen`.

### C. Continue with Google
- The user taps **"Continue with Google"** and authorizes their Google account. 
- *Note: Google immediately creates a Firebase authentication record the moment they verify.*
- Lumora detects if they are a completely **new user** (`isNewUser == true`).
- The app suspends routing them to the home screen and forces the `QuestionnaireScreen` to pop up.
- Once they **pass**, they are routed directly to the `GoogleProfileCompletionScreen` to finish setting up their Lumora profile.

---

## 2. How High-Risk Users are *Prevented* from Creating an Account

If a user hits any of the risk triggers (e.g., answering "Yes" to self-harm thoughts, or having a highly impaired functional score), the app immediately halts all registration pathways to prioritize their safety.

### A. Standard Email Sign-Up
- The user is halfway through or finishes answering the `QuestionnaireScreen`.
- The evaluation logic triggers a flag.
- Instead of showing the `SignupScreen`, they are permanently redirected to the **`HighRiskScreen`**. 
- Because they never reached the `SignupScreen`, **no Firebase account is ever created**, and no data is saved. They can only return to the Welcome screen or use the emergency numbers provided.

### B. Continue as Guest (Anonymous)
- The user finishes the `QuestionnaireScreen`.
- The evaluation logic triggers a flag.
- The user is redirected to the **`HighRiskScreen`**.
- The questionnaire returns a failure signal to the Login Screen.
- The `signInAnonymously()` Firebase command is **aborted and never executed**. No guest account is created on your backend.

### C. Continue with Google (Advanced Mitigation)
- *The Problem:* By the time we know the Google user is high-risk, Firebase has *already* created their account record in the database during the OAuth popup.
- *The Solution:* 
  1. The user takes the `QuestionnaireScreen`.
  2. The evaluation logic triggers a flag.
  3. Before navigating to the `HighRiskScreen`, the questionnaire executes a **hard deletion** of the user's account from your backend: `FirebaseAuth.instance.currentUser?.delete()`.
  4. It returns a failure signal to the Login Screen.
  5. The Login Screen performs a local **Sign Out** (`_authService.signOut()`) to clear any remaining cached tokens.
  6. The user is left at the `HighRiskScreen` with emergency resources.
  7. **Result:** The user is completely wiped from the Lumora Firebase Authentication database, ensuring they have no account access.

---

## 3. How High-Risk Users are Measured

The app utilizes a 15-question screening tool based on a 4-point scale (0-3) for Sections A-C and Yes/No (1-0) options for Sections D-E. A user is automatically classified as **High-Risk** and blocked from creating an account if they meet **any** of the following criteria during the evaluation:

### 1. Critical Risk Screening (Immediate Block)
If the user answers **"Yes"** to any of the critical safety questions in **Section D** (Questions 10-13):
- Thoughts of harming themselves.
- Feeling that life is not worth living.
- Having a recent plan to hurt themselves.
- Currently being in an unsafe situation.

### 2. Extremely High Overall Severity
The user receives an **Extremely High Total Score (>= 14 out of 18)** combined across:
- **Section A (Emotional Severity):** Questions 1-3 (Hopelessness, emotions out of control, unbearable distress).
- **Section B (Daily Functioning):** Questions 4-6 (Work/school attendance, basic daily tasks, relationship problems).

### 3. Severe Daily Functioning Impairment
The user receives a **Severe Functioning Score (>= 7 out of 9)** specifically in **Section B** (Questions 4-6), indicating they are entirely unable to complete basic human needs like eating, hygiene, sleeping, or attending school/work.
