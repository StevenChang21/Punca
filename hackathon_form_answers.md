# Hackathon Judging Form — Draft Answers

## CATEGORY A: IMPACT (60 Points Total)

### PROBLEM STATEMENT & SDG ALIGNMENT (15 Points)

---

**Q1: What real-world problem is your project solving?**

In Malaysian secondary schools, students receive graded math papers with red marks but no explanation of *why* they got it wrong or *how* to fix their understanding. Over time, these unresolved gaps compound — a student who doesn't grasp fractions in Form 1 will inevitably struggle with algebra in Form 2. This leads to frustration, math anxiety, and a permanent loss of confidence that follows students throughout their academic journey.

On the other side, teachers managing classes of 30–40 students simply cannot diagnose every individual's weaknesses. When exam results drop, they resort to the only option they have: revising the *entire* syllabus from scratch — wasting precious class hours on topics that most students have already mastered, simply because they have no visibility into *which specific concepts* each student is struggling with.

This is a widespread problem across Malaysian public schools, disproportionately affecting students from lower-income families who cannot afford private tutoring. The result is a widening achievement gap where students who fall behind early rarely catch up.

---

**Q2: Describe the UN Sustainable Development goal(s) and target(s) chosen for your solution.**

Our project aligns with **UN Sustainable Development Goal 4: Quality Education** — specifically:

- **Target 4.1**: Ensure that all girls and boys complete free, equitable, and quality primary and secondary education leading to relevant and effective learning outcomes.
- **Target 4.a**: Build and upgrade education facilities that are child, disability, and gender sensitive and provide safe, non-violent, inclusive, and effective learning environments for all.
- **Target 4.c**: Substantially increase the supply of qualified teachers, including through international cooperation for teacher training in developing countries — Punca AI achieves this by amplifying each teacher's effectiveness through AI-powered analytics, effectively multiplying their capacity to deliver targeted instruction.

---

**Q3: Based on the answer from previous question, describe the reason(s) behind it**

The connection between our problem and SDG 4 is direct: quality education requires that every student actually *learns*, not just attends class. In Malaysia, the 2022 PISA results showed that Malaysian 15-year-olds scored significantly below the OECD average in mathematics (with a mean score of 409 vs. the OECD average of 472), indicating that many students are completing secondary school without achieving basic math proficiency.

The root cause is not a lack of teaching — it is a lack of *diagnostic feedback*. Students make mistakes but never learn the root cause, so errors persist and compound. Teachers want to help but lack the tools to identify individual weaknesses at scale.

Punca AI directly addresses SDG Target 4.1 by ensuring that learning outcomes actually improve — not through more teaching hours, but through smarter, AI-powered diagnosis of each student's specific gaps. For students, it provides the personalized one-on-one feedback that was previously only available through expensive private tutoring, democratizing access to quality learning support. For teachers, it provides AI-aggregated class analytics (heatmaps, gap analyses, top weakness alerts) that transform guesswork into data-driven instruction — directly supporting Target 4.c by multiplying each teacher's effectiveness without requiring additional staff.

---

---

### USER FEEDBACK & ITERATION (15 Points)

---

**Q4: How did you validate your solution with real users?**

We validated Punca AI with **11 Form 2 students (age 14)** at **Archive Tuition Centre**, conducted 3 days before the final hackathon demo. As Steven (our team lead) is a math tuition teacher at the centre, we had direct access to real students and their actual math worksheets.

The validation was conducted in two stages:
1. **Verbal Interviews (Post-Exam)**: Immediately after the students finished their math exam, Steven conducted brief verbal interviews with a few students who were still present, asking whether they would want to use an app like this when revising or in their studies. Some students had already left by then, which led to scheduling a separate demo session.
2. **Live In-Class Demo + Paper Surveys**: On a separate day (3 days before the hackathon deadline), Steven demonstrated the app in front of the class using one of the students' actual exam papers as input, so students could see the AI analyze real mistakes they had made. Because the app is still an MVP and not fully stable, we deliberately chose not to install it on students' personal devices — this ensured honest, risk-free feedback. After the demo, each student filled out a 5-question anonymous paper survey rating the app on first impressions, curiosity to explore, perceived usefulness, ease of use, and open-ended comments.

---

**Q5: Share three key insights from user feedback.**

1. **Students wanted Chinese (中文) translations to understand math terms (SURPRISING)**: Several students — particularly those from Chinese vernacular school backgrounds — wrote comments like *"use normal Chinese, let me easy understand"* on the survey. This surprised us because the initial version only had English/BM explanations. We didn't anticipate how strongly students from Chinese-medium primary schools would want math concepts bridged through their mother tongue — especially using everyday spoken Chinese, not formal textbook jargon.

2. **The AI explanations had too much text and not enough visuals (STRUGGLE)**: During the demo, students found the mini-lesson explanations overwhelming — long walls of text with no visual elements. When asked verbally, students expressed that they wanted more diagrams and visual aids to help them understand concepts like geometry and algebraic expansion, rather than reading paragraph after paragraph.

3. **Students found the app genuinely useful and easy to use (MOST VALUABLE)**: Despite being an MVP, students rated the app highly — with responses of 5/5 for "I think this app will help me improve my study" and 1/5 for "The app seems hard to use" (meaning they found it easy). First impressions included *"Excellent, easy for me to understand."* Students particularly valued seeing their own mistakes analyzed and explained back to them — something no existing tool in their learning environment provides.

---

**Q6: What three changes did you make based on user input?**

1. **Chinese Translation Bridge (Vocabulary Bridge)**
   - *Feedback*: Students wrote "use normal Chinese, let me easy understand" and verbally expressed difficulty connecting English/BM math terms to concepts they originally learned in Chinese.
   - *Change*: We implemented a 4-tier configurable Chinese (中文) translation system — from math-terms-only to full bilingual — injected directly into every AI-generated explanation. We specifically prompted the AI to use everyday spoken Simplified Chinese rather than formal textbook jargon.
   - *Result*: Students from Chinese vernacular backgrounds can now bridge the language gap gradually, with the option to reduce the Chinese level over time as their BM/English proficiency improves.

2. **Gradual Disclosure for Mini-Lessons**
   - *Feedback*: Students found the AI-generated mini-lessons too long and overwhelming — too many words in a single block of text.
   - *Change*: We redesigned the mini-lesson UI to deliver content **chunk-by-chunk** using a progressive disclosure pattern. Instead of showing the entire lesson at once, students tap through bite-sized steps, each building on the previous one.
   - *Result*: Lessons feel less intimidating. Students can digest one concept at a time and pace themselves, reducing cognitive overload.

3. **Inline SVG Diagrams in Explanations**
   - *Feedback*: Students expressed a need for more visual elements to accompany text-based explanations, especially for geometry and spatial topics.
   - *Change*: We added AI-generated inline SVG diagrams directly within the mini-lessons. The Gemini prompt now instructs the model to embed simple SVG visuals (with labeled sides, angles, and right-angle markers) wherever a diagram would aid understanding.
   - *Result*: Geometry and visual topics now include clear, contextual diagrams rendered directly in the lesson — making abstract concepts concrete and reducing reliance on pure text.

---

### SUCCESS METRICS (10 Points)

---

**Q7: How do you measure your solution's success?**

We define three specific, measurable outcomes:

1. **Mastery Score Improvement Per Topic**: Each time a student uploads a new assessment on the same KSSM chapter, their mastery score for that topic is updated in the Mastery Grid. Success is measured by whether a student's score on a previously weak topic increases over time after completing the AI-generated remediation drills. For example, if a student scored 45% on Algebraic Expansion and later scores 72% on a follow-up worksheet, the mastery grid reflects this improvement directly.

2. **Remediation Drill Completion & Level-Up Rate**: We track how many students complete the full remediation cycle (mini-lesson → quiz → Level 1 challenge → Level 2 challenge). A high completion rate indicates that the content is engaging and appropriately paced. A student who successfully reaches Level 2 demonstrates that they have progressed from basic recall to applying the concept in new contexts.

3. **Reduction in Repeated Weakness Types**: By tracking the gap type distribution (foundation / execution / precision) across a student's assessments over time, we can measure whether foundational errors decrease as students engage with the remediation system. A shift from majority "foundation" gaps to "precision" gaps indicates that students are building conceptual understanding and only making careless mistakes — a sign of genuine learning progress.

---

**Q8: What Google technologies power your analytics?**

Our analytics pipeline is powered by **Cloud Firestore** and **Google Gemini** working together:

- **Cloud Firestore (Real-Time Database)**: All assessment results, weakness classifications, and remediation drill outcomes are stored in Firestore across 5 collections (users, assessments, weaknesses, classrooms, assignments). Firestore's real-time sync and composite query indexes allow us to run aggregation queries instantly — for example, fetching all weaknesses for a student filtered by gap type, or all assessment scores for a class sorted by date.

- **Google Gemini (AI-Powered Classification)**: Every weakness is automatically classified by Gemini into one of three gap types (foundation, execution, precision) and mapped to a specific KSSM syllabus chapter. This AI-generated structured metadata is what makes our analytics meaningful — without it, we would only have raw scores with no diagnostic insight.

- **Custom Analytics Layer (Built on Firestore)**: We built a custom analytics engine on top of Firestore that computes: (1) **Mastery Grid** — per-topic mastery percentages using the latest assessment score mapped via KSSM syllabus IDs, (2) **Gap Analysis** — percentage distribution of foundation/execution/precision errors per student, and (3) **Class Heatmap** — a teacher-facing aggregation that iterates over all students in a classroom and builds a topic × performance matrix showing class-wide strengths and weaknesses.

As the app is still an MVP, we have not yet integrated Firebase Analytics for usage tracking. In a future release, we plan to add Firebase Analytics to track user engagement metrics (session duration, feature usage, retention) and Firebase Crashlytics for stability monitoring.

---

### AI INTEGRATION (20 Points)

---

**Q9: Which Google AI technology did you implement?**

We implemented **Google Gemini 3 Flash** (model: `gemini-3-flash-preview`) via the **Google AI Studio / Gemini Developer API**, using the official `google_generative_ai` Dart SDK. No non-Google AI is used.

Key implementation details:
- **Multimodal Input**: We use Gemini's multimodal capabilities to send raw images (JPEG) and PDFs directly as `DataPart` binary content alongside structured text prompts — enabling the model to read and interpret handwritten student work.
- **Structured JSON Output**: We enforce `responseMimeType: 'application/json'` in the `GenerationConfig`, forcing Gemini to return valid JSON conforming to our custom schema. This eliminates fragile regex parsing and allows direct deserialization into Dart model classes.
- **Three Distinct AI Pipelines**: (1) Assessment Analysis — multimodal image/PDF analysis with a structured 3-step diagnostic protocol, (2) Remediation Drill Generation — context-aware mini-lesson and quiz generation, (3) Level-Up Challenge — progressive difficulty question generation based on previous drill context.
- **Model Fallback**: If `gemini-3-flash-preview` returns a 503 (overloaded) error, the system automatically retries the same request with `gemini-2.0-flash` as a stable fallback.

---

**Q10: How does AI make your solution smarter?**

AI is not an add-on — it IS the core engine. Without AI, Punca AI could not exist. Here are concrete examples of what AI enables that would be impossible otherwise:

1. **Reading Handwritten Math**: A student snaps a photo of their messy handwritten worksheet. Gemini's multimodal vision reads the handwriting, interprets mathematical notation (fractions, exponents, algebraic expressions), and transcribes it into structured LaTeX. No OCR engine or static rule set could handle the variety of handwriting styles, crossed-out work, and mixed notation that real student papers contain.

2. **Diagnosing the Root Cause, Not Just the Wrong Answer**: Traditional grading just marks answers right or wrong. Gemini follows a 3-step diagnostic protocol (Inventory → Analysis → Clustering) to determine *why* each mistake happened. For example, if a student writes `2(x+3) = 2x+3`, Gemini identifies this as an *execution* error in bracket expansion — not a foundational misunderstanding of algebra. This classification drives the type of remediation generated.

3. **Generating Personalized Content On-the-Fly**: Every mini-lesson, quiz question, SVG diagram, vocabulary bridge, and level-up challenge is dynamically generated by Gemini based on the student's specific mistake and gap type. There is no static question bank. If a student struggles with expanding `(x+3)²`, the AI generates a lesson explaining that specific pattern, a quiz testing it with different numbers, and progressively harder challenges — all in real time.

4. **Multilingual Adaptation**: The AI dynamically adapts its output language based on the student's preference — generating everything in Bahasa Melayu or English, with configurable levels of inline Chinese (中文) translation. The language instructions are injected directly into the prompt, and Gemini seamlessly produces bilingual content in a single generation.

---

**Q11: What would your solution lose without AI?**

If AI were removed, **every core feature would break**:

- **Assessment Analysis → Completely broken**: Without Gemini, we cannot read handwritten student work, transcribe math notation, grade answers, or identify mistakes. The app would become a camera that uploads photos to nowhere. There is no non-AI fallback for interpreting handwritten mathematics.

- **Root Cause Diagnosis → Impossible**: The 3-tier gap classification (foundation / execution / precision) is entirely AI-generated. Without it, we lose the ability to tell students *why* they're wrong and teachers lose all diagnostic insight. The mastery grid, gap analysis, and class heatmap would all show empty data.

- **Remediation System → Completely broken**: Every mini-lesson, quiz, vocabulary bridge, and level-up challenge is generated by Gemini on-the-fly. With no AI, there is no content to show — no lessons, no quizzes, no progressive challenges. We would need to build and maintain a massive static content database for every topic×error-type combination, which is impractical and cannot personalize to individual mistakes.

- **Teacher Analytics → Reduced to raw scores only**: Teachers would only see test scores with no breakdown of *which concepts* students are struggling with or *what type* of errors they're making. The "Top Weakness" alerts and per-student gap analysis that make teacher live mode actionable would disappear entirely.

In short, removing AI would reduce Punca AI from an intelligent diagnostic tutor to a basic photo storage app with a gradebook — which is exactly the problem we set out to solve in the first place.

---

### TECHNOLOGY INNOVATION (10 Points)

---

**Q12: What makes your approach unique?**

Existing alternatives fall into two categories — and Punca AI fills the gap between them:

- **AI homework solvers** (Photomath, Mathway) tell students the *correct answer* and show steps to get there. They solve FOR the student but never diagnose WHY the student got it wrong. They also don't connect to any classroom or teacher workflow.
- **Learning platforms** (Khan Academy, Quizizz) provide generic content libraries. Students must self-diagnose their weaknesses and manually search for the right topic to study. Teachers get engagement metrics but no diagnostic insight into error patterns.

**Punca AI is different in 4 key ways:**

1. **Diagnosis-first, not answer-first**: We analyze the student's *own* work to identify the root cause of each mistake, classified into foundation/execution/precision gap types. The AI doesn't solve the problem — it explains why the student's approach failed.
2. **Teacher-in-the-loop**: Unlike pure student-facing tools, Punca AI has a complete teacher side with live class heatmaps, per-student gap analysis, and AI-generated remediation packs that teachers can review and edit before assigning. This keeps human oversight in the loop.
3. **Curriculum-aligned**: Every weakness is mapped to the Malaysian KSSM syllabus (Form & Chapter). This isn't generic math — it's contextualized to the exact curriculum these students are studying.
4. **Multilingual bridge**: The 4-tier Chinese translation system is purpose-built for Malaysian students transitioning from Chinese vernacular primary schools to BM/English secondary education — a real demographic need that no existing platform addresses.

---

**Q13: What's the growth potential?**

In 2–3 years, Punca AI can grow along three axes:

1. **Subject & Syllabus Expansion**: The current architecture is not math-specific — the 3-step diagnostic protocol and gap classification framework can be adapted to Science, Bahasa Melayu comprehension, and other KSSM subjects. The KSSM syllabus mapping is modular (stored in `kssm_syllabus.dart`) and can be extended to Forms 3–5 and additional subjects with minimal code changes.

2. **Scale Through Tuition Centres First**: Malaysian public schools currently do not allow students to use mobile phones on campus, making direct school deployment impractical in the near term. Instead, our first growth vector is partnering with **private tuition centres** — where mobile devices are commonly used and teachers have more autonomy over their tools. Malaysia has thousands of tuition centres serving millions of students, and many tuition teachers (like Steven) are already managing the exact pain point Punca AI solves. Once proven at scale through tuition centres, the platform can expand to public schools via teacher-facing web dashboards or tablet-based deployments in computer labs.

3. **AI-Driven Teacher Professional Development**: As the system accumulates data on common student misconceptions across thousands of classrooms, it can surface national-level insights — e.g., "72% of Form 2 students nationwide struggle with algebraic expansion due to sign errors." This data could inform teacher training programs, textbook revisions, and MOE curriculum updates, transforming Punca AI from a classroom tool into a national education intelligence platform.

---

### TECHNICAL ARCHITECTURE (5 Points)

---

**Q14: Which Google Developer Technologies did you use and why?**

1. **Flutter** — We chose Flutter as our frontend framework because it allows us to build a single Dart codebase that runs on both iOS and Android. For a hackathon team with limited time, this was critical — we could focus on building features instead of maintaining two separate codebases. Flutter's Material 3 design system also gave us a polished, modern UI out of the box, and its widget ecosystem provided ready-made support for LaTeX rendering (`flutter_math_fork`) and SVG display (`flutter_svg`), both essential for math content.

2. **Google Gemini (via Google AI Studio)** — We chose Gemini over alternatives like OpenAI or Claude because of its native multimodal capabilities (reading images and PDFs in the same request), its structured JSON output mode (`responseMimeType: 'application/json'`), and the generous free tier via Google AI Studio. Gemini's long context window was also essential for our assessment analysis pipeline, which sends multiple page images plus a detailed prompt with the entire KSSM syllabus structure in a single request.

3. **Firebase Authentication** — Chosen for seamless integration with Flutter and built-in role management. It allowed us to implement student/teacher role-based access with minimal code, and Firebase Auth's `authStateChanges()` stream made reactive UI updates trivial.

4. **Cloud Firestore** — We chose Firestore over alternatives like Supabase or a traditional SQL database because of its real-time sync capabilities, flexible NoSQL schema (ideal for storing nested AI-generated JSON responses), and tight integration with the Firebase ecosystem. Composite indexes enabled efficient queries for our teacher analytics (e.g., fetching assessments sorted by date per student).

5. **Firebase Storage** — Used to store uploaded student worksheet images and PDFs. Chosen for its direct integration with Firebase Auth (security rules) and simple SDK within Flutter.

---

**Q15: Briefly go through your solution architecture**

Our architecture follows a **client-heavy, serverless** pattern with three layers:

**1. Presentation Layer (Flutter App)**
The Flutter app handles all UI rendering and user interaction. It is split into three feature modules: `auth` (login/signup with role selection), `student` (camera, analysis, remediation, dashboard, classroom, profile), and `teacher` (classroom management, student drill-down, heatmap, remediation preview, homework assignment). State is managed via `StatefulWidget` with service classes instantiated directly — keeping the architecture simple and hackathon-appropriate.

**2. AI Layer (Google Gemini via Google AI Studio)**
The `GeminiService` class manages all communication with the Gemini API. It runs three independent pipelines: (1) Assessment Analysis accepts multimodal image/PDF input and returns structured JSON with weaknesses, gap classifications, and syllabus mappings; (2) Remediation Generation takes a weakness context and produces a mini-lesson, vocabulary bridge, and quiz; (3) Challenge Generation creates progressively harder questions. All pipelines enforce JSON output via `GenerationConfig` and include automatic model fallback (Gemini 3 Flash → 2.0 Flash).

**3. Data Layer (Firebase)**
Firebase provides the entire backend: Authentication for user identity and roles, Cloud Firestore for persistent storage across 5 collections (users, assessments, weaknesses, classrooms, assignments), and Firebase Storage for uploaded images. The `FirebaseService` class handles all CRUD operations, batch writes for weakness denormalization, and aggregation queries for teacher analytics (mastery grid, gap analysis, class heatmap). No custom backend server is needed — all logic runs client-side or in Gemini.

**Why this structure:** For a hackathon MVP, a serverless architecture eliminates the overhead of managing a backend server than enabling rapid iteration. Firebase handles scaling, authentication, and real-time data sync automatically, while Gemini handles all AI computation via API calls. This lets the team focus entirely on building user-facing features.

---

### IMPLEMENTATION & CHALLENGES (5 Points)

---

**Q16: Describe a significant technical challenge you faced.**

Our biggest technical challenge was **AI hallucination and misidentification**. During early testing, Gemini would occasionally miss obvious mistakes after analyzing many questions, or worse, invent mistakes that didn't exist — marking a correct answer as wrong. For a diagnostic tool, this is catastrophic because it destroys student trust.

**Debugging process:** We analyzed dozens of raw Gemini JSON responses logged to `gemini_debug_log.json` and identified a pattern: the model would lose accuracy when processing many questions in a single pass, especially near the end of long worksheets. It was "fatiguing" — rushing through later questions without careful verification.

**Solution:** We implemented a rigorous **3-Step Guided Protocol** baked directly into the prompt: (1) **Inventory & Scorecard** — forces the model to scan ALL pages top-to-bottom and list every single question with a status (Correct/Incorrect/Partial) before making any judgments; (2) **Detailed Analysis** — only then does it analyze the flagged questions against the KSSM syllabus; (3) **Clustering** — groups related errors to avoid fragmented output. We also added **Visual Verification rules** for geometry diagrams (forcing the model to verify numerical labels and hash marks) and an **Error Carried Forward (ECF) policy** so the AI doesn't penalize a student twice for the same upstream error.

A second major challenge was **LaTeX rendering corruption**: Dart's `jsonDecode()` was silently converting LaTeX backslash sequences into ASCII control characters (e.g., `\frac` → form-feed + "rac", `\times` → tab + "imes"). The fix was a 4-line `_restoreLatex()` utility that maps control characters back to their backslash forms — but finding the root cause took hours because control characters are invisible in most log viewers.

A third challenge was **making AI explanations actually understandable** for struggling students. A technically correct explanation is useless if a 14-year-old can't follow it. We addressed this through prompt engineering: instructing Gemini to explain like "a friendly big brother," use concrete numbers instead of abstract concepts, minimize mathematical jargon, and deliver lessons in bite-sized chunks via progressive disclosure.

---

**Q17: What technical trade-offs did you make?**

1. **Client-side AI calls vs. backend proxy**: We chose to call the Gemini API directly from the Flutter client rather than routing through a backend server. This eliminated server costs and deployment complexity, but it means the API key is bundled in the app binary. We mitigated this by storing the key in a gitignored `secrets.dart` file and applying API key restrictions (Android package + SHA-1, iOS bundle ID) in the Google Cloud Console. For a production release, we would move to a Cloud Functions proxy.

2. **StatefulWidget vs. state management framework**: We used simple `StatefulWidget` with direct service instantiation instead of Provider, Riverpod, or Bloc. This was a deliberate trade-off: for a hackathon MVP with a small team, the overhead of setting up a state management framework would have slowed development with no user-visible benefit. The downside is that some screens have complex `setState` logic that would benefit from separation of concerns, but this is acceptable technical debt for an MVP.

3. **Denormalized weaknesses (stored twice) vs. normalized storage**: We store weaknesses both nested inside each `assessments` document AND as flat documents in a separate `weaknesses` collection. This duplicates data, but it was necessary because Firestore doesn't support querying nested arrays efficiently. The nested copy drives the per-assessment UI, while the flat collection enables fast cross-assessment aggregation for teacher analytics (gap analysis, heatmaps). The trade-off is data consistency — if we ever need to update a weakness, we'd need to update it in two places.

4. **Separate prompts vs. single mega-prompt**: We deliberately split the assessment analysis and remediation generation into separate Gemini API calls instead of asking the model to do everything in one request. The analysis prompt is already large (multimodal images + full KSSM syllabus + 3-step protocol), so adding mini-lesson generation on top would bloat the context window and degrade the quality of both the diagnosis and the lesson. By keeping each pipeline focused on a single task — analysis only diagnoses, remediation only teaches — we minimize context tokens and maximize the quality of each response independently.

---

### SCALABILITY (10 Points)

---

**Q18: Outline the future steps for your project and how you plan to expand it for a larger audience.**

**Phase 1 (3–6 months) — Stabilize & Validate:**
- Conduct a proper **longitudinal impact study** with 2–3 tuition centres: baseline test → 4 weeks of Punca AI usage → follow-up test, measuring actual score improvement and student confidence.
- Add **gamification** — visual elements, animations, XP/badge systems, and streak tracking to make the remediation process feel more like a game and less like extra homework. This directly addresses student engagement beyond the novelty phase.
- Integrate Firebase Analytics and Crashlytics for usage tracking and stability monitoring.

**Phase 2 (6–12 months) — Expand Content & Reach:**
- **Broader subject support**: Extend beyond mathematics to Science, Bahasa Melayu comprehension, and other KSSM subjects using the same diagnostic framework. Also expand KSSM coverage from Form 1–2 to Form 1–5.
- Launch a **web-based teacher dashboard** so teachers in classrooms (where phone usage is restricted) can access analytics on a laptop or school computer.
- Partner with tuition centre chains to onboard hundreds of teachers simultaneously.

**Phase 3 (1–3 years) — Platform & Scale:**
- **Teacher-driven AI fine-tuning**: Allow teachers to upload official KSSM marking schemes and rubrics so the AI's grading and analysis aligns exactly with how exams are scored in Malaysian schools — ensuring feedback matches real-world assessment standards.
- Build a **"Highlight & Ask AI"** feature (requested by students during user testing) where students can drag-select any section of the analysis and ask the AI follow-up questions in a conversational chat.
- Explore B2B partnerships with state education departments for deployment in school computer labs, using tablet-based or web-based versions that don't require student mobile phones.

---

**Q19: Explain how the current technical architecture supports scaling or can be adapted for a larger audience.**

Our architecture is inherently scalable because it is **fully serverless** — every component auto-scales without manual infrastructure management:

1. **Firebase Auto-Scaling**: Cloud Firestore automatically handles concurrent reads/writes at scale. As more students and teachers use the app, Firestore distributes load across Google's infrastructure with no code changes required. Firebase Authentication similarly scales to millions of users. Firebase Storage uses Google Cloud Storage under the hood, which handles unlimited file uploads.

2. **Gemini API Scales on Demand**: The Gemini Developer API is a managed service — we don't host any models. As usage grows, API calls scale horizontally. Our model fallback strategy (Gemini 3 Flash → 2.0 Flash on 503) already handles temporary overload gracefully. For higher throughput, we can upgrade to a paid Gemini API tier or batch non-urgent requests (e.g., teacher-assigned remediation packs can be generated asynchronously).

3. **Modular Syllabus System**: The KSSM syllabus is stored as a structured Dart constant (`kssm_syllabus.dart`) with a clean `getPrompt()` interface. Adding new forms, subjects, or even entirely different national curricula only requires adding new data entries — no architectural changes. The AI prompt, model classes, and Firestore schema are all syllabus-agnostic.

4. **Cross-Platform via Flutter**: The app already compiles for both iOS and Android from a single codebase. Expanding to web (Flutter Web) or desktop requires minimal platform-specific code, enabling us to serve students on phones and teachers on classroom laptops simultaneously.

5. **Minor Changes for Production Scale**: To move from MVP to production, we would: (a) route Gemini API calls through Firebase Cloud Functions instead of client-side calls, centralizing API key management and enabling rate limiting; (b) add Firestore security rules to enforce role-based data access; (c) introduce offline caching with Firestore's built-in persistence so students can review past assessments without internet.

---

> [!NOTE]
> These are draft answers. Review and adjust the tone, add any personal anecdotes from your teaching experience, and verify the PISA statistics before submitting.
