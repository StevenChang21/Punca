# Punca AI 🎓
**Your Empathetic AI Tutor for Personalized Learning**

Punca AI is a hackathon project built to revolutionize how students overcome learning hurdles. By combining the multi-modal capabilities of **Google Gemini 1.5 Pro** with the cross-platform power of **Flutter**, Punca AI doesn't just grade homework—it understands *why* a student made a mistake and provides a personalized path to mastery.

---

## 🌟 Key Features

### 📸 AI Assessment Analysis
Snap a photo of your math worksheet or essay. Punca AI uses **Gemini 3 Flash** to:
-   **Transcribe** handwritten text and complex mathematical notation (LaTeX).
-   **Grade** the work instantly.
-   **Diagnose** the root cause of errors (e.g., "Concept misunderstanding" vs. "Calculation error").

### 🧠 Personalized Remediation
Understanding the mistake is just the start. Punca AI generates:
-   **Targeted Drills**: Custom practice questions generated on-the-fly to address specific weaknesses.
-   **Confidence Builders**: Encouraging feedback to reduce math anxiety.
-   **Learning Roadmap**: A step-by-step plan to close knowledge gaps.

### 👩‍🏫 Teacher Mode (Demo)
Empowering educators with data.
-   **Class Analytics**: View aggregate performance and common stumbling blocks.
-   **Student Tracking**: Identify at-risk students who need intervention.
-   *Accessible via the "Switch to Teacher View" button in the Student Profile.*

### 📊 Persistent History
-   **Track Progress**: All assessments and remediation drills are saved to **Firebase Firestore**.
-   **Review**: Revisit past mistakes and see how you've improved over time.

---

## 🛠️ Google Technology Integration

This project is a showcase of the Google developer ecosystem:

### 1. Google Gemini 1.5 Pro 🧠
The core intelligence of Punca AI. We utilize Gemini's **multimodal capabilities** to process images of handwritten work and its **long-context reasoning** to generate pedagogically sound feedback and remedial questions without hallucinating.

### 2. Flutter 💙
Built from a single codebase for mobile, web, and desktop. Flutter ensures a smooth, high-performance UI with custom animations and a beautiful Material 3 design.

### 3. Firebase 🔥
-   **Firebase Authentication**: Secure, effortless user sign-in.
-   **Cloud Firestore**: Real-time scalable database for storing student assessments, drill results, and class data.
-   **Firebase Storage**: Securely hosting images of student work.

---

## 🚀 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/punca_ai.git
    cd punca_ai
    ```

2.  **Setup Environment Variables**:
    -   Create a `.env` file in the root directory.
    -   Add your Google AI Studio API key (get one from [Google AI Studio](https://aistudio.google.com/)):
        ```
        GEMINI_API_KEY=your_api_key_here
        ```

3.  **Run the App**:
    ```bash
    flutter pub get
    flutter run
    ```
