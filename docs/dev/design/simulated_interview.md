# Simulated Interview Feature Design

The Simulated Interview feature provides users with a realistic practice experience for the US Citizenship Test interview. The feature simulates a one-on-one interview scenario that follows the actual test format, allowing users to practice answering questions verbally.

The interview order is randomized each session to mimic the unpredictability of the real interview. The app uses speech recognition to capture user responses and evaluates them for correctness and fluency.

## Interview Flow
1. **Introduction Screen**: Briefly explains the interview process and provides a "Start Interview" button.
2. **Greeting and Small Talk**: The app uses Text-to-Speech (TTS) to greet the user and engage in brief small talk to set a comfortable tone.
3. **Question Loop**: The interview consists of a series of questions drawn from the following
   - The app plays a question audio prompt using TTS.
   - The user responds verbally.
   - The app captures the response using speech recognition (already implemented - works offline).
   - **Scoring**: The response evaluator determines correctness (Pass/Partial/Fail).
   - **Conversation**: The LLM generates natural interviewer response based on score:
     - **Pass**: Natural acknowledgment, move to next question
     - **Partial/Unclear**: Follow-up question or clarification request
     - **Fail**: Neutral acknowledgment (don't reveal incorrect), move to next question
   - The LLM's response is played via TTS to maintain conversational flow.
4. **Completion Screen**: Summarizes performance, including number of correct answers and areas for improvement.

## Test Sections (order randomized)
- English Speaking Test
  - Ability to speak English evaluated throughout entire interview.
  - Reading: User reads 1 out of 3 sentences aloud (displayed on screen).
  - Writing: User writes 1 out of 3 sentences (given through audio prompt).
- Civics Test
  - User must answer 12 out of 20 questions correctly.
- Questions are asked from the application and background (Form N-400) section. (Future enhancement)

## Technical Implementation

### Speech Recognition
- **Package**: `speech_to_text`
- Captures user responses in real-time.
- **Already implemented** in reading/writing practice features.
- Works fully offline after initial setup.

### Text-to-Speech (TTS)
- **Package**: `flutter_tts`
- Plays question prompts and instructions.
- Configured for natural-sounding speech.

### Response Evaluation

#### Hybrid Evaluation Approach
The interview uses a **two-component system** that separates conversational flow from answer scoring:

**1. Answer Scoring (Existing Infrastructure)**
- **Reading**: Uses existing `ReadingEvaluator` service with Levenshtein distance
- **Writing**: Reuses `ReadingEvaluator` service 
- **Civics Questions**: Enhanced `ReadingEvaluator` with keyword matching for factual accuracy
  - Checks for key terms/facts in user response
  - Calculates similarity score
  - Returns Pass/Partial/Fail classification
- **Future Consideration**: Rename `ReadingEvaluator` to `TextEvaluator` or `ResponseEvaluator` for clarity

**2. Conversational Flow (Local LLM)**
- **Purpose**: Generate natural, realistic interview dialogue
- **Responsibilities**:
  - Provide conversational acknowledgments ("Good", "Correct", "I see")
  - Generate follow-up questions when score is Partial/Unclear
  - Request clarification naturally ("Could you explain that a bit more?")
  - Manage transitions between interview sections
  - Create realistic interviewer responses that match tone of actual USCIS interviews
- **Input**: Question, user response, score from evaluator (Pass/Partial/Fail)
- **Output**: Natural language response and next action (continue/follow-up/move on)

#### Local LLM Integration (Primary Implementation Task)

**Model Decision: DistilGPT-2**

We will use **DistilGPT-2** as the local LLM for conversational interview simulation.

**Rationale:**
1. **Purpose-built for text generation**: GPT-based models excel at generating natural, varied conversational responses—critical for realistic interview simulation
2. **Size/performance balance**: ~82MB (FP32) compresses to ~20-30MB with INT8 quantization while maintaining quality
3. **Proven mobile performance**: Achieves 10-15 tokens/sec on mid-range devices, sufficient for short interview responses (1-2 second latency)
4. **License compatibility**: Apache 2.0 license is fully compatible with this MIT-licensed project
5. **Broad device support**: Works on ~80% of active smartphones (2020+) with quantization

**Alternatives considered but rejected:**
- MobileBERT: Too small (~25MB) but BERT models struggle with conversation generation; better suited for classification
- GPT-Neo-125M: Better quality but too large (125MB+) for mobile bundle
- Gemini Nano: Excellent performance but extremely limited device support (Pixel 8+, S24+ only)

**Implementation Details:**
- **Deployment**: Convert to TensorFlow Lite (TFLite) format and bundle as Flutter asset
- **Optimization**: Use INT8 quantization to reduce size and improve inference speed
- **Strategy**: 
  - Feed interview in small pieces with concise prompts to minimize context size
  - Use multiple short requests rather than long conversation history
  - Scoring handled separately by evaluator, LLM receives result
  - LLM focuses solely on generating natural conversational responses
  - Limit response generation to 20-30 tokens max for speed
- **Performance targets**:
  - Model size: <30MB (with INT8 quantization)
  - Inference latency: <2 seconds per response (target), <3 seconds (acceptable)
  - Token generation rate: 10-15 tokens/sec on mid-range devices

**Minimum Device Requirements:**
- Android 10+ with 4GB+ RAM, mid-range processor (Snapdragon 600-series or equivalent)
- iOS 13+ (iPhone X and newer)
- Covers ~80% of active smartphone market

**Note**: This is the most complex component and should be developed as a standalone feature before full interview integration

### Data Storage
- Questions and answers stored in local SQLite database.

## Implementation Phases

### Phase 1: Local LLM Integration (Prerequisite)
This is the most significant technical challenge and should be completed independently before tackling the full interview feature.

**Tasks**:
1. Obtain DistilGPT-2 model from Hugging Face
2. Convert model to TensorFlow Lite format with INT8 quantization
3. Bundle TFLite model as Flutter asset
4. Create inference service for on-device model execution
5. Design prompt engineering strategy for conversational responses
   - Templates for acknowledgments, follow-ups, clarifications
   - Maintain neutral, professional USCIS interviewer tone
   - Keep prompts concise to minimize context
   - Limit generation to 20-30 tokens per response
6. Develop prototype conversation interface for testing realistic dialogue
7. Performance testing and optimization for target devices
   - Test on mid-range Android (Snapdragon 600-series)
   - Test on older iOS devices (iPhone X/XS)
   - Measure latency, memory usage, battery impact

**Key Deliverables**:
- TFLite model (<30MB) bundled in assets
- Flutter service for model inference
- Demo app showing conversational responses
- Performance benchmarks on target devices

**Update - Implementation Decision (February 2026)**:

After implementing DistilGPT-2 integration, we discovered the model is **unsuitable for this use case**:

**Problems Encountered**:
1. **Poor Output Quality**: Model generated repetitive, nonsensical responses ("I'm sorry, sir" repeated)
2. **Failed Instruction-Following**: Could not follow "Rephrase this professionally" meta-instructions
3. **Unacceptable Latency**: 60-90 seconds per response (target was <2 seconds)
4. **Model Size**: Even at 82M parameters, too small for reliable instruction-following

**Current Implementation**:
- Using **pre-written professional variations** with randomization
- Instant response time, perfect quality, no model download required
- 3-5 hand-crafted variations per prompt type for natural variety
- Maintains professional USCIS interview tone

**Future Enhancement Options**:
1. **Larger On-Device Model**: Gemma 2B or Phi-2 (2.7B params)
   - Better instruction-following, but 10x larger (200-300MB)
   - Still 20-30 second latency on mobile
2. **Cloud API**: Gemini Flash or GPT-4o-mini
   - Fast (<1 second), high quality, minimal cost (~$0.0001/request)
   - Requires internet connection
3. **Hybrid Approach**: Cloud API with offline fallback to variations

**Decision**: Defer LLM integration until suitable mobile models become available or implement cloud API with proper offline handling. Current variation-based approach provides excellent UX without the complexity.

### Phase 2: Interview Feature Implementation
Once LLM integration is proven viable, implement the full interview experience.

**Prerequisites**:
- Working LLM conversation service
- Existing speech recognition (already implemented)
- Existing TTS system (already implemented)
- Enhanced `ResponseEvaluator` service with keyword matching for civics questions

**Tasks**:
1. Design interview state management (question sequence, scoring, progress)
2. Build interview UI (introduction, question display, response capture)
3. Integrate evaluator + LLM flow (score → conversational response)
4. Implement section transitions (speaking test → civics → completion)
5. Create completion/results screen with performance summary
6. Testing with realistic interview scenarios
