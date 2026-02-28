# Punca AI 🎓
**Your Empathetic AI Tutor for Personalized Learning**

## 🎯 Purpose and Problem Statement
Education is a two-way street — yet the current system fails both sides. **Students** receive a "red X" on their homework with no explanation of *why* they got it wrong or *how* to fix their understanding. Over time, these unresolved gaps compound, leading to frustration, math anxiety, and a loss of confidence. **Teachers**, on the other hand, are stretched thin across large classes. When exam results drop, they often have no choice but to revise the *entire syllabus* from scratch — wasting precious class time on topics most students have already mastered, simply because they lack visibility into *which specific concepts* each student is struggling with.

**Punca AI** was built to solve both sides of this problem. For **students**, it acts as an empathetic, always-available AI tutor that diagnoses the root cause of every mistake and provides a personalized, step-by-step path to mastery. For **teachers**, it surfaces AI-aggregated analytics — class-wide heatmaps, individual gap analyses, and the top weakness across the class — so they can walk into every lesson with a data-driven plan and teach *exactly* what their students need most.

## 🌍 Alignment with AI and SDGs
Punca AI directly aligns with **UN Sustainable Development Goal 4 (SDG 4): Quality Education**. Our mission is to ensure inclusive and equitable quality education and promote lifelong learning opportunities for all.
- **AI for Personalized Learning (Students)**: By leveraging advanced large language models (Google Gemini), Punca AI democratizes access to one-on-one tutoring. AI allows us to read handwritten student work, comprehend complex mathematical workflows, and dynamically generate custom remediation drills — a level of personalization previously only available through expensive private tutoring.
- **AI for Smarter Teaching (Teachers)**: Teachers no longer need to guess where students are struggling. AI-generated class analytics, heatmaps, and per-student gap analyses empower educators to make data-driven decisions, focus their limited contact hours on high-impact topics, and assign targeted remediation — dramatically improving the quality and efficiency of instruction.
- **Closing the Achievement Gap**: By addressing foundational gaps early through our "step-down" approach on the student side, and giving teachers precise visibility into class-wide weaknesses, we help prevent students from falling permanently behind.

---

## 🌟 Key Features

### 📸 AI Assessment Analysis
Upload photos of your math worksheets or PDFs directly. Punca AI uses **Gemini 3 Flash** powered by **Google AI Studio** to:
-   **Multi-Image & PDF Upload**: Supports batch multi-page image upload and direct PDF analysis for complete worksheet coverage.
-   **Transcribe** handwritten text and complex mathematical notation into LaTeX.
-   **Grade** the work instantly with an approximate score.
-   **Diagnose** the root cause of each error using a **3-Step Guided Protocol** aligned with **Newman's Error Analysis Framework**:
    1.  **Inventory & Scorecard**: The AI scans every page from top to bottom and lists every single question it finds (e.g. 1(a), 1(b), 2). Each question is marked as *Correct*, *Incorrect*, or *Partial*. This ensures no question is missed and creates a complete map of the student's work before any judgement is made. It also applies an **Error Carried Forward (ECF) rule** — if a student uses a wrong value from a previous part but applies the correct method in the next, they are not penalised twice.
    2.  **Detailed Analysis**: The AI goes through the inventory and only analyses questions marked *Incorrect* or *Partial*. For each, it identifies the specific mistake, compares it against the KSSM Syllabus, and classifies the error into one of three gap types:
        - *Foundation* — the student didn't know which concept or formula to use.
        - *Execution* — the student chose the right method but applied it incorrectly.
        - *Precision* — a careless slip such as a reading or sign error.
    3.  **Clustering (Consolidation)**: Instead of producing one card per mistake, the AI groups related errors together. Mistakes from the same question are merged into a single weakness entry, and similar mechanical errors across questions (e.g. sign errors + expansion errors) are consolidated under a broader topic like "Algebraic Accuracy." This prevents overwhelming the student with fragmented feedback and produces fewer, denser, more actionable weakness cards.
-   **KSSM Syllabus Mapping**: Each weakness is automatically mapped to the Malaysian KSSM syllabus (Form & Chapter), providing actionable curriculum references.

### 🧠 Personalized Remediation
Understanding the mistake is just the start. Punca AI dynamically generates:
-   **Confidence Builders**: Encouraging feedback highlighting what the student did well, to reduce math anxiety.
-   **Simple comparison between correct and incorrect answer**: Highlights the step where the student started to made a mistake and the correct way to solve it. A red box that contains student's own working and a green box that contains the correct working for student to easily view where their answers differ from the correct ones.
-   **Actionable Step**: A clear instruction for student to follow to improve their weakness (e.g. Review form 1 chapter 10.1 to revise how to calculate the area of triangle) which is shown in the explanation dropdown under each weakness identified.
-   **Mini-Lessons**: Bite-sized explanations with LaTeX-rendered math, inline SVG diagrams for visualization, and a step-by-step teaching flow delivered chunk-by-chunk so students can digest the content at their own pace.
-   **Vocabulary Bridge**: The Chinese (中文) translation serves as an assistive feature to help multilingual Malaysian students bridge language barriers, especially those who came from Chinese vernacular schools. Students can slowly reduce the level of Chinese translation in the profile page as their English or Malay proficiency increases.
-   **Targeted Quiz Drills**: AI-generated multiple-choice questions testing the exact weakness after student have gone through the mini-lesson.
-   **Level Up Challenges**: A 3-level progressive difficulty system. After getting a question right, students can attempt harder variations (trickier numbers → new contexts/word problems) to build mastery.

### 📊 Student Profile & Progress Tracking
-   **Mastery Grid**: A visual grid showing mastery percentage for each topic, color-coded (green/orange/red) to highlight strengths and weaknesses at a glance.
-   **Focus Area Card (Purple card)**: Automatically identifies the student's weakest topic and recommends it as their current priority.
-   **Persistent History**: All assessments, remediation drills, and homework results are saved to **Firebase Firestore** for long-term tracking.
-   **Classroom Enrollment**: Students can join teacher-created classrooms using a code, view classmates, and receive assigned homework.

### 🌐 Multilingual Support
-   **Base Language Toggle**: Switch between Bahasa Melayu (BM) and English (DLP) for all AI-generated content.
-   **Chinese Bridge (4 Levels)**: Configurable Chinese translation support — from math-terms-only (数学词) to instruction and key terms (指令和关键词) to full bilingual (全双语) — designed for students coming from vernacular chinese schools to help them navigate math in a second language.

### 👩‍🏫 Teacher Live Mode
Empowering educators with real-time data and classroom management. User will log in as teacher in the authentication page.
-   **Classroom Management**: Create custom classrooms and generate unique access codes for students to join.
-   **Live Class Heatmap**: A real-time, color-coded visualization of class performance across different topics to instantly identify shared weaknesses.
-   **Live Student List**: View all enrolled students in real-time and drill into individual student profiles showing their full assessment history, gap analysis, and specific stumbling blocks.
-   **Actionable Analytics & Alerts**: Automatically aggregates the "Top Weakness" across the class and provides alerts for students needing immediate intervention.
-   **AI-Powered Remediation Packs**: Uses Google AI Studio to generate targeted, personalized practice packs based on individual student gaps, which teachers can **review and edit** (title, lesson, question, options) before assigning as homework.
-   **Homework Assignment Flow**: Assigned drills appear in the student's classroom as homework. Students complete the lesson and quiz, and completion status is tracked back to the teacher.

---

## 💡 Innovation & Explanation of Implementation
Our core innovation lies in shifting AI from a simple "homework solver" to a **pedagogical diagnostic tool** with a **teacher-in-the-loop design**.
- **Multimodal Handwriting Analysis**: Instead of forcing students to type complex math equations, Punca AI uses Gemini's multimodal capabilities to analyze photos (or PDFs) of raw, handwritten work. It transcribes the text, interprets the math (formatting it into LaTeX), and follows the student's logical steps line-by-line using a structured 3-step protocol (Inventory → Analysis → Clustering).
- **3-Tier Error Classification**: Every mistake is classified as *foundation* (concept error), *execution* (process error), or *precision* (careless error), enabling the AI to generate appropriately targeted remediation.
- **The "Step-Down" Approach**: If a student fails a complex algebra problem because they struggle with basic fractions, Punca AI recognizes the foundational gap. It "steps down" the difficulty, generating practice problems focused *only* on fractions, before stepping back up to the original algebra concept via the Level Up challenge system.
- **Dynamic Content Generation**: We don't rely on a static question bank. Every mini-lesson, quiz, SVG diagram, vocabulary bridge, and learning roadmap is computationally generated on-the-fly by Gemini, perfectly tailored to the individual student's current mistake and gap type.
- **Teacher-in-the-Loop**: AI-generated remediation packs are not blindly assigned. Teachers can preview, edit, and customize every component — the lesson text, quiz question, and answer options — before assigning, ensuring pedagogical quality and human oversight.
- **Data-Driven Teaching, Not Guesswork**: Traditionally, when students perform poorly, teachers resort to revising the *entire* syllabus — wasting precious class time on topics students have already mastered. Punca AI changes this by surfacing AI-aggregated insights (via the Live Class Heatmap and Top Weakness analytics) that pinpoint *exactly* which topics and which students are struggling. Teachers can now walk into class knowing that "60% of my students are failing Linear Equations because of sign errors," and dedicate their limited time to targeted, high-impact instruction instead of broad, inefficient revision.

---

## ⚡ Challenges Faced & Future Plans

### Development Challenges
1. **AI Hallucination & Misidentification**: One of the biggest hurdles was Gemini occasionally misidentifying questions — for example, missing an obvious mistake after analysing many questions or inventing a mistake that didn't exist. Solving this required **rigorous prompt engineering**: implementing the structured 3-step protocol (Inventory → Analysis → Clustering), adding visual verification rules for geometry diagrams, and enforcing an Error Carried Forward (ECF) policy so the AI doesn't penalise a student twice for the same upstream error.
2. **Student-Friendly UI for Complex Content**: Presenting AI analysis, LaTeX-rendered equations, SVG diagrams, and multi-step lessons in a way that is readable, non-intimidating, and engaging for students was a significant design challenge. We invested heavily in chunked lesson delivery, color-coded weakness cards (red for mistakes, green for corrections), and progressive disclosure so students are never overwhelmed by a wall of information.
3. **Making AI Explanations Actually Understandable**: A technically correct explanation is useless if a struggling student can't understand it. We had to carefully prompt engineer the mini-lesson generation so that Gemini minimizes the use of mathematical jargon and instead uses **simple layman language with relatable analogies**. The AI is instructed to explain concepts like "a friendly big brother" would — using concrete numbers and visual examples rather than abstract academic terminology.

### Testing & Validation Challenges
1. **Limited Time to Measure Impact**: With only 2 weeks remaining before the hackathon deadline and one full week lost to the Chinese New Year holiday, there was insufficient time to conduct a proper longitudinal study measuring the impact on student learning journeys. A first baseline test was conducted in the **2nd week of February** to gauge initial student performance, but there was no opportunity for a follow-up assessment to measure improvement.
2. **Responsible MVP Distribution**: As the app is still an MVP and not fully stable, it would have been irresponsible to distribute it directly onto students' personal devices. Instead, Steven conducted a **live in-class demo** where students could see the app in action using one of the student working as example, and then distributed **paper surveys** to collect their feedback on the concept, UI, and perceived usefulness — ensuring honest student input without the risks of deploying unstable software.

### Future Plans
- **Gamification**: Add more visual elements, animations, XP/badge systems, and streak tracking to make the remediation process feel more like a game and less like extra homework.
- **Broader Subject Support**: Expand beyond mathematics to other subjects in the KSSM syllabus.
- **Longitudinal Impact Tracking**: Conduct proper before-and-after studies with real classrooms to measure the quantitative impact on student grades and confidence.
- **Teacher-Driven AI Fine-Tuning**: Allow teachers to fine-tune the AI's grading and analysis to be more closely aligned with official KSSM answer schemes and marking rubrics, ensuring the AI's feedback matches exactly how exams are scored in Malaysian schools.

---

## 🛠️ Technical Implementation Overview
This project showcases a powerful, cross-platform architecture driven by the Google developer ecosystem:

### Google Technologies Used
1. **Google Gemini 3 Flash (via Google AI Studio) 🧠**: The core intelligence engine. We use the `gemini-3-flash-preview` model through the Gemini Developer API for multimodal image/PDF processing and long-context pedagogical reasoning. It powers three distinct AI pipelines: assessment analysis, remediation drill generation, and level-up challenge generation.
2. **Flutter 💙**: The cross-platform frontend framework, allowing us to build a beautiful, high-performance mobile application for both iOS and Android from a single Dart codebase, with Material 3 design, custom animations, and LaTeX/SVG rendering.
3. **Firebase 🔥**: Our scalable backend infrastructure.
   - **Firebase Authentication**: Seamless and secure user login and role management (student/teacher).
   - **Cloud Firestore**: A NoSQL real-time database to store user profiles, assessment history, remediation drills, classroom data, homework assignments, and teacher analytics.
   - **Firebase Storage**: Secure cloud storage to host uploaded images and PDFs of student worksheets.

---

## � Implementation Details

### AI Prompt Pipeline Architecture
Punca AI runs **three distinct Gemini pipelines**, each served by the same `GeminiService` class but with independently crafted prompts:

1. **Assessment Analysis Pipeline** (`analyzeImages`) — Accepts multi-page images or a PDF as multimodal `DataPart` inputs alongside a structured text prompt. The prompt enforces a strict **3-Step Guided Protocol** (Inventory → Analysis → Clustering) so the model processes the student's work systematically rather than jumping to conclusions. A full copy of the KSSM syllabus structure is injected directly into the prompt via `KssmSyllabus.getPrompt()`, giving the model the reference material it needs to map every weakness to a specific Form and Chapter.
2. **Remediation Drill Pipeline** (`generateRemediation`) — Takes a single `Weakness` object as context (topic, reason, mistake example, correction) and generates a complete micro-remediation package: a mini-lesson, vocabulary bridge, MCQ question, and step-by-step explanation.
3. **Level-Up Challenge Pipeline** (`generateChallengeDrill`) — Receives the previous drill's question and the weakness context, and generates a progressively harder variant. Level 1 changes numbers (e.g. introduces negatives or fractions); Level 2 changes context (e.g. word problems or inverse tasks).

### Structured JSON Output Enforcement
All three pipelines use Gemini's native **`responseMimeType: 'application/json'`** setting in the `GenerationConfig`. This forces the model to return valid JSON directly, eliminating the need for regex-based extraction of JSON from markdown code blocks. The expected JSON schema is defined inline within the prompt text itself (e.g., `{"subject": "...", "weaknesses": [...]}`) so the model conforms to our exact field structure. On the client side, the raw response is decoded via `jsonDecode()` and passed directly into Dart model factories (`AssessmentResult.fromAnalysis`, `RemediationDrill.fromJson`).

### Model Fallback Strategy
The primary model is `gemini-3-flash-preview`. If a **503 (overloaded)** error is encountered during assessment analysis, the service automatically falls back to `gemini-2.0-flash` and retries the same `Content.multi(parts)` request — ensuring the student never sees a blank error screen even under high API load.

### End-to-End Data Flow
```
Student Upload → Image Picker / PDF Picker
        ↓
Firebase Storage (upload images, get download URLs)
        ↓
GeminiService.analyzeImages() → Gemini API (multimodal)
        ↓
JSON Response → jsonDecode → AssessmentResult.fromAnalysis()
        ↓
FirebaseService.saveAssessment() → Firestore 'assessments' collection
        ↓  (also)
FirebaseService.saveWeaknesses() → Firestore 'weaknesses' collection (batch write)
        ↓
UI: AnalysisResultScreen renders weakness cards, mistake/correction boxes
        ↓
Student taps "Remediation" → GeminiService.generateRemediation()
        ↓
RemediationDrill.fromJson() → UI: Mini-lesson chunks, vocabulary bridge, MCQ quiz
        ↓
Student answers correctly → GeminiService.generateChallengeDrill() (Level 1, then Level 2)
```

### Firestore Database Schema
The app uses **5 top-level Firestore collections**:

| Collection | Key Fields | Purpose |
|---|---|---|
| `users` | `uid`, `displayName`, `email`, `role` (student/teacher), `form`, `classroomIds[]` | User profiles and role-based access |
| `assessments` | `studentId`, `imageUrls[]`, `subject`, `grade`, `syllabusIds[]`, `weaknesses[]` (nested), `remediationDrills[]` (nested), `createdAt` | Complete assessment records with embedded weakness and drill data |
| `weaknesses` | `studentId`, `topic`, `gap_type`, `reason`, `form_id`, `chapter_id`, `createdAt` | Denormalized weakness entries for fast aggregation queries (teacher analytics) |
| `classrooms` | `teacherId`, `teacherName`, `name`, `code`, `studentIds[]`, `isDemo` | Classroom membership and access codes |
| `assignments` | `studentId`, `classroomId`, `status`, `score`, `assignedDate`, drill data | Teacher-assigned homework tracking |

Weaknesses are stored **both** nested inside the `assessments` document (for per-assessment display) **and** as flat documents in the `weaknesses` collection (for cross-assessment aggregation in teacher analytics). Composite Firestore indexes on `(studentId, createdAt)` and `(studentId, classroomId, assignedDate)` enable efficient sorted queries.

### LaTeX Restoration
A critical implementation challenge: Dart's `jsonDecode` interprets JSON escape sequences literally, so `\frac` becomes a form-feed character + "rac", and `\times` becomes a tab + "imes". The `_restoreLatex()` utility in `assessment_model.dart` reverses this by mapping control characters back to their backslash-prefixed forms (`\t → \\t`, `\f → \\f`, `\b → \\b`, `\r → \\r`), ensuring LaTeX strings render correctly in the `flutter_math_fork` widget.

### Language Preference Injection
Language settings are stored locally via `SharedPreferences` and managed by the `LanguagePreferences` class. Before every Gemini API call, `LanguagePreferences.promptInstruction` is injected directly into the prompt text. This dynamically constructs a language instruction block based on two axes:
- **Base Language** — Bahasa Melayu (BM) or English (DLP), controlling the primary language of all AI output.
- **Chinese Level** (4 tiers) — Off → Math Terms Only (数学词) → Terms + Steps (词+步骤) → Full Bilingual (全双语). Each tier adds progressively more Simplified Chinese translations inline, with explicit prompt rules to ensure everyday spoken Chinese rather than formal textbook jargon.

### Teacher Analytics Pipeline
On the teacher side, `FirebaseService` aggregates raw student data into actionable insights:
- **Mastery Grid Calculation** (`getMasteryStats`) — Pre-fills every KSSM Form 1–2 chapter as a key, then overlays the latest assessment score per chapter using `SyllabusPointer` IDs for robust matching (not string-based topic matching). Unattempted chapters return `null` (displayed as grey), while attempted chapters are color-coded by score.
- **Gap Analysis** (`getGapAnalysis`) — Queries the `weaknesses` collection for a student and computes the percentage distribution across the three gap types (foundation / execution / precision), powering the donut chart on the teacher's student detail view.
- **Class Heatmap** — Iterates over all students in a classroom, fetches each student's mastery stats, and aggregates them into a class-wide topic × performance matrix for heatmap visualization.

---

## �🚀 Setup Instructions

### Prerequisites
Before you begin, ensure you have the following installed:
- [Git](https://git-scm.com/downloads)
- A [Google AI Studio API Key](https://aistudio.google.com/)
- A Firebase project set up via the [Firebase Console](https://console.firebase.google.com/)

### For macOS
1. **Install Flutter SDK**:
   - Download the Flutter SDK for macOS from the [official website](https://docs.flutter.dev/get-started/install/macos).
   - Extract the file and add the `flutter/bin` directory to your global `PATH`.
2. **Install Xcode**:
   - Download Xcode from the Mac App Store to run the iOS simulator and build iOS apps.
   - Run `sudo xcodebuild -license` in your terminal and agree to the terms.
   - Install CocoaPods: `sudo gem install cocoapods`.
3. **Install Android Studio**:
   - Download [Android Studio](https://developer.android.com/studio).
   - Install the Android SDK, Android SDK Command-line Tools, and Android SDK Build-Tools via the SDK Manager.
4. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/Punca.git
   cd Punca
   ```

### For Windows
1. **Install Flutter SDK**:
   - Download the Flutter SDK for Windows from the [official website](https://docs.flutter.dev/get-started/install/windows).
   - Extract the zip file (e.g., to `C:\src\flutter`) and add `C:\src\flutter\bin` to your Environment Variables `PATH`.
2. **Install Android Studio**:
   - Download and install [Android Studio](https://developer.android.com/studio).
   - Go to the SDK Manager and install the latest Android SDK, Command-line Tools, and Build-Tools.
3. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/Punca.git
   cd Punca
   ```

### Project Configuration (All Platforms)
1. **Verify Flutter Setup**: Run `flutter doctor` in your terminal to ensure there are no missing dependencies.
2. **Setup Environment Variables**:
   - Create a `.env` file in the root directory of the project.
   - Add your Gemini API key:
     ```
     GEMINI_API_KEY=your_api_key_here
     ```
3. **Firebase Configuration**:
   - Install the Firebase CLI: `npm install -g firebase-tools`
   - Log in to your Firebase account: `firebase login`
   - Activate FlutterFire CLI: `dart pub global activate flutterfire_cli`
   - Configure your project: `flutterfire configure` (select your corresponding Firebase project).
   - **Create Composite Indexes**: The app uses Firestore queries that require composite indexes. Go to your [Firebase Console → Firestore → Indexes](https://console.firebase.google.com/) and create the following:

     | Collection | Fields | Order |
     |---|---|---|
     | `assessments` | `studentId` (Ascending), `createdAt` (Descending) | — |
     | `assignments` | `studentId` (Ascending), `assignedDate` (Descending) | — |
     | `assignments` | `studentId` (Ascending), `classroomId` (Ascending), `assignedDate` (Descending) | — |

     > **Tip**: Alternatively, when you first run the app and trigger these queries, the Firestore console log will show a direct link to create each missing index automatically.
4. **Install Dependencies and Run**:
   ```bash
   flutter pub get
   flutter run
   ```

> [!IMPORTANT]
> **For Testing & Judging**: Please use **Form 1 and Form 2 Malaysian KSSM Mathematics** student working/papers only. The AI analysis, syllabus mapping, and remediation drills have been optimized and rigorously tested for these levels. Other forms or syllabi may work but have not been thoroughly validated yet.
