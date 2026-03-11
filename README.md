# Internship Test Assignment — Realtime Team Mini-Game (Flutter + Firebase RTDB)

![image.png](attachment:dedc2513-ef2b-41e6-b3b2-4ff182727458:image.png)

link video: [https://drive.google.com/drive/folders/1N4-UCJ4_Qmw2ncicN6B2iacjWYChknVx?usp=drive_link](https://drive.google.com/drive/folders/1N4-UCJ4_Qmw2ncicN6B2iacjWYChknVx?usp=sharing)

---

## 🎯 Overview

Build a **Flutter (Android/iOS)** multiplayer mini-game that simulates a realtime competitive tower-solving challenge.

### Game Mechanics

- **8 players maximum**, divided into **2 teams**: Team A vs Team B
- Each team has:
    - A **Target number** (identical for both teams, e.g., `1000`)
    - **20 active towers**, each with a unique **Start value** (e.g., `10, 20, 25, 10, 40`)
- Players solve towers by reaching **Target** from **Start** using ONLY:
    - **Button 1:** `+10` (add 10)
    - **Button 2:** `×2` (multiply by 2)
- **Win Condition:** The team that solves the **most towers** within **5 minutes** wins
- When a tower is solved, a **new tower** is auto-generated to maintain 20 active towers

---

## ⚠️ MANDATORY REQUIREMENTS

### 🤖 AI-Assisted Development (REQUIRED)

**You MUST use AI tools during development:**

- Allowed AI assistants: Claude (Anthropic), ChatGPT, GitHub Copilot, Cursor, or similar
- **AI Review Required:** Your code must be reviewed by an AI assistant for:
    - Code quality and best practices
    - Architecture improvements
    - Bug detection
    - Performance optimization
    - Security considerations

**Proof Required:**

- Include screenshots/logs of AI interactions in your submission
- Add a `AI_USAGE.md` file documenting:
    - Which AI tools you used
    - What aspects were AI-assisted (architecture, debugging, optimization, etc.)
    - Key improvements suggested by AI
    - Code sections where AI provided significant help

---

## 🏗️ Technical Stack Requirements (MANDATORY)

## 🔥 Flame Engine Integration (MANDATORY IMPLEMENTATION)

The game MUST integrate **Flame Engine** for rendering and game interaction.

Flame will be used to provide a proper **game loop, component system, and animation handling** instead of relying solely on standard Flutter widgets.

### Required Flame Usage

The following parts of the game MUST be implemented using **Flame Engine**:

1. **Game Board Rendering**
    - The tower arena for each team should be rendered using Flame components.
    - Towers should be implemented as **Flame Components**.
    - Visual states must be represented through Flame rendering:
        - 🟢 Available
        - 🟡 Claimed
        - ✅ Solved
2. **Game Loop**
    - Use Flame's internal game loop for:
        - Updating tower states
        - Animations
        - Timer visual updates
        - Real-time UI effects
3. **Tower Interaction**
    - Towers must be tappable through Flame input handlers:
        - `TapCallbacks`
        - `TapDetector`
    - Tapping a tower triggers the **claim tower attempt logic** through Firebase.
4. **Animations**
Flame animations should be used for:
    - Tower solved animation
    - Tower claim highlight
    - Success effects when a player solves a tower
    - Visual feedback for invalid moves
5. **Game Component Structure**

Suggested structure:

```

class TowerChallengeGame extends FlameGame with TapDetector {
}

class TowerComponent extends PositionComponent with TapCallbacks {
}

class TeamArenaComponent extends PositionComponent {
}
```

Each tower should be represented as a **TowerComponent**.

1. **Flutter + Flame Hybrid Architecture**

The project must combine **Flutter UI + Flame Game Engine**:

Flutter handles:

- Lobby
- Player list
- Scoreboards
- Overlays
- Menus
- Simulation controls

Flame handles:

- Arena rendering
- Tower interactions
- Game animation
- Real-time visual updates

Example integration:

```

GameWidget(
game: TowerChallengeGame(),
)
```

1. **Performance Considerations**

Using Flame ensures:

- Efficient rendering for 20+ towers per team
- Smooth animations
- Proper game lifecycle management
- Clean separation between **game logic** and **UI**
1. **Why Flame is Required**

Flame is required to ensure:

- The project demonstrates **game development capability**, not only UI programming
- Proper use of **game loops, components, and rendering systems**
- Scalable architecture for multiplayer game environments

Submissions that **do not implement Flame Engine will be considered incomplete**.

---

### Flutter Architecture

- **State Management:** GetX (REQUIRED)
    - Use GetX for all state management
    - Implement proper reactive programming patterns
    - Use GetX dependency injection
- **Architecture:** Clean Architecture (REQUIRED)
    - **Presentation Layer:** UI + GetX Controllers
    - **Domain Layer:** Use cases, entities, repository interfaces
    - **Data Layer:** Repository implementations, data sources (Firebase)
    
    ```
    lib/
    ├── core/
    │   ├── constants/
    │   ├── utils/
    │   └── errors/
    ├── features/
    │   ├── game/
    │   │   ├── presentation/
    │   │   │   ├── controllers/
    │   │   │   ├── pages/
    │   │   │   └── widgets/
    │   │   ├── domain/
    │   │   │   ├── entities/
    │   │   │   ├── repositories/
    │   │   │   └── usecases/
    │   │   └── data/
    │   │       ├── repositories/
    │   │       ├── datasources/
    │   │       └── models/
    ```
    

### Backend

- **Firebase Realtime Database** (RTDB)
- Implement proper RTDB transactions for concurrency
- Security rules implementation

---

## 📱 Feature Requirements

### 1) Main Match Screen (Portrait Mode)

**Layout:**

- Screen split vertically (50/50):
    - **Top half:** Team A arena
    - **Bottom half:** Team B arena

**Each Team Arena Displays:**

- **Target value** (far left, prominent display)
- **20 towers** in a scrollable grid/list showing:
    - `startValue` (e.g., "42")
    - Visual `state` indicator:
        - 🟢 Available (tappable)
        - 🟡 Claimed (locked, show who claimed it)
        - ✅ Solved (greyed out, show solver + moves)
- **Team score** counter
- **Timer countdown** (shared, synced from Firebase)

**Auto-regeneration:**

- When a tower is solved → immediately generate a new tower
- New towers must match between both teams (same start values, same order)

**Tower Generation Rules:**

- Random `startValue` within range `5..100`
- Must be solvable within the numeric constraints
- Both teams receive identical tower sets

---

### 2) Tower Attempt Overlay (Modal)

**Trigger:** User taps an **Available** tower in their team

**Flow:**

1. Attempt to **claim the tower** via Firebase RTDB transaction
2. If claim succeeds → open modal overlay
3. If claim fails → show toast "Tower already claimed"

**Interaction:**

- Each button press applies operation and increments move counter
- **Win condition:** `currentValue == Target`
    - Commit **solved** state to Firebase (transactional)
    - Close overlay
    - Show success animation
- **Unreachable condition:**
    - Both operations invalid (would exceed max range)
    - Show "Unreachable - Please Restart" message
    - Force user to restart or close

**Restart Button:**

- Resets local state: `current = startValue`, `moves = 0`
- Does NOT release the claim (user can keep trying)

---

### 3) Numeric Constraints

**Hard Rules:**

- Integers only
- Range: `0 ≤ value ≤ 200,000`
- Operations:
    - `+10`: Add 10 to current value
    - `×2`: Multiply current value by 2
- **Invalid Move:** Operation result exceeds 200,000 or goes below 0
    - Move button should be disabled/greyed out
    - Do NOT apply the operation

---

### 4) AFK Detection System (REQUIRED)

**Player Activity Monitoring:**

- Track player's `lastSeenAt` timestamp in Firebase
- Update every 5 seconds while app is active
- **AFK threshold:** 30 seconds of inactivity

**Auto-release Claimed Towers:**

- If a player goes AFK while claiming a tower:
    - Automatically release the tower after 15 seconds
    - Set tower state back to `available`
    - Notify other players tower is available again

**AFK Player Indicator:**

- Show AFK badge on player list
- Dim/grey out AFK players in team roster

**Score Tracking:**

- Track and display:
    - Towers solved per player
    - Average moves per solve
    - Time spent on each tower
    - AFK time percentage

---

## 🤖 Simulation Mode (Bot Players)

**Purpose:** Test realtime coordination with a single device

**Implementation Options:**

1. **In-app bots** using Dart isolates/timers
2. **Multiple app instances** on different devices/emulators

**Bot Behavior:**

- Randomly select available towers from assigned team
- Use the optimal solver algorithm (or near-optimal with random delays)
- Commit solves to Firebase like real players
- Simulate human timing (1-3 second delays between moves)

**Debug Controls:**

- UI to launch 1-6 bots
- Assign bots to teams (auto-balance or manual)
- Start/stop bot simulation
- Adjust bot "skill level" (optimal vs random moves)

---

## 🗄️ Backend Requirements — Firebase Realtime Database (Must)

Use Firebase RTDB as the source of truth for live match state.

### Recommended Data Model (You may adjust, keep it clear)

`/liveMatches/{matchId}`

- `meta`: `{ status: lobby|running|ended, startAt, endAt, durationSec }`
- `teams`:
    - `A`:
        - `targetValue`
        - `opAdd`: `a`
        - `opMul`: `m`
        - `score`
        - `towers`:
            - `{towerId}`:
                - `startValue`
                - `state`: `available|claimed|solved`
                - `claimedBy`: `uid`
                - `claimExpiresAt`: `timestamp`
                - `solvedBy`: `uid`
                - `solvedAt`: `timestamp`
                - `movesTaken`: `int`
                - `optimalMoves`: `int`
    - `B`: same structure as `A`
- `players`:
    - `{uid}`: `{ team, displayName, lastSeenAt }`

**Optional Extensions for AFK Detection & Stats:**
You may optionally extend the `players` node with additional fields:

- `isAFK`: `boolean`
- `stats`: `{ towersSolved, totalMoves, averageMoves, afkTimeSeconds }`

---

## 🔒 Concurrency Requirements (Must)

### 1) Claim Tower (RTDB Transaction)

Claim only if:

- `state == available` **OR**
- claim is expired (`claimExpiresAt < now`)

On success:

- set `state = claimed`
- set `claimedBy = uid`
- set `claimExpiresAt = now + 15s`

### 2) Solve Tower (RTDB Transaction)

Solve only if:

- `claimedBy == uid`
- claim not expired
- `state != solved`

On success:

- set `state = solved`
- set solved metadata: `solvedBy`, `solvedAt`, `movesTaken`, `optimalMoves`
- increment team score **transactionally**

### 3) Release Tower (Best Effort)

When overlay closes without solving:

- optionally set tower back to `available`
- expiry handling alone is acceptable

---

## ⏱️ Timer (Must)

- Store `endAt` in RTDB `meta` and show countdown in clients.
- When time hits `endAt`, set `status = ended`
    - can be done by a "host" client, or by a simple Cloud Function (optional)

---

## 🧮 Solver Requirement (Must)

Implement a minimum-moves solver for:

- operations: `+10`, `×2`
- state range: `0..200000`
- output: minimum moves **Y** for **Best possible: Y**

Suggested approach:

- **BFS shortest path** since each operation costs 1 move
(Nodes are values, edges are operations, bounded by max range)

---

## 🔐 Security Rules (Lightweight OK)

Not production-grade is fine, but include basic protection:

- users can't solve towers for the other team
- users can't edit other users' player nodes

If full rules are too time-consuming:

- include a short note describing what you would enforce in production

---

## 📊 Assessment & Grading

**Total Points: 100**

### 1. Core Functionality (40 points)

- ✅ Game mechanics work correctly (10 pts)
- ✅ Tower claiming & solving with transactions (10 pts)
- ✅ Real-time synchronization across devices (10 pts)
- ✅ Timer and match lifecycle (5 pts)
- ✅ Auto-generation of new towers (5 pts)

### 2. Algorithm Implementation (15 points)

- ✅ BFS optimal solver correctness (10 pts)
- ✅ Performance & edge case handling (5 pts)

### 3. AFK Detection System (15 points)

- ✅ Player activity tracking (5 pts)
- ✅ Auto-release of claimed towers (5 pts)
- ✅ AFK indicators in UI (3 pts)
- ✅ Player statistics tracking (2 pts)

### 4. Architecture & Code Quality (15 points)

- ✅ Clean Architecture implementation (5 pts)
- ✅ GetX state management proper usage (5 pts)
- ✅ Code organization and readability (3 pts)
- ✅ Error handling and edge cases (2 pts)

### 5. AI Usage & Review (10 points)

- ✅ AI_USAGE.md documentation quality (3 pts)
- ✅ Evidence of AI-assisted development (3 pts)
- ✅ Implementation of AI-suggested improvements (4 pts)

### 6. Simulation Mode (5 points)

- ✅ Bot implementation and behavior (3 pts)
- ✅ Multi-bot coordination testing (2 pts)

**Bonus Points (up to +10):**

- (+5) Advanced BFS reachability check for "unreachable" detection
- (+3) Cloud Functions for match management
- (+2) Beautiful UI/UX with animations
- (+5) Comprehensive Firebase Security Rules
- (+3) Unit tests for solver algorithm
- (+2) Integration tests for Firebase transactions

---

## 📤 Submission Format

**Deadline:** [INSERT DEADLINE DATE]

**Email to:** `studyosystemio@gmail.com`

**Subject Line:** `Flutter Tower Challenge - [Your Full Name]`

**Email Body Template:**

```
Name: [Your Full Name]
Link Repository: [GitHub/GitLab public repo URL]
Link Video Explanation: [YouTube/Drive unlisted video URL]
Link APK: [Google Drive/Dropbox direct download link]
Additional Notes: [Optional - any challenges faced, extra features, etc.]
```

---

## 📹 Video Explanation Requirements (MANDATORY)

**Language:** English (Required)

**Duration:** 5-10 minutes

**Content to Cover:**

1. **Game Flow Demo (2-3 min)**
    - Show main match screen
    - Demonstrate tower claiming
    - Show solving process
    - Demonstrate AFK detection
    - Show bot simulation mode
2. **Algorithm Explanation (2-3 min)**
    - Explain your BFS implementation
    - Walk through code
    - Show example: Start=42, Target=1000, how algorithm finds shortest path
    - Explain time/space complexity
3. **Architecture Overview (2-3 min)**
    - Show Clean Architecture folder structure
    - Explain GetX controllers and state management
    - Show Firebase transaction implementations
    - Explain AFK detection logic
4. **AI Usage Discussion (1-2 min)**
    - Which AI tools you used
    - How AI helped improve your code
    - Show 1-2 examples of AI suggestions you implemented

**Format:**

- Screen recording with voiceover (English)
- Show both code and running app
- Use annotations/highlights to emphasize key points
- Upload to YouTube (unlisted) or Google Drive (public link)

---

## 📦 Deliverables

- Source code repo (GitHub/GitLab)
- **README.md** including:
    - setup steps (Firebase config, run instructions)
    - how to start a match & simulation mode
    - short architecture notes (RTDB structure, transactions, solver)
- **AI_USAGE.md** documenting:
    - Which AI tools you used (Claude, ChatGPT, Copilot, etc.)
    - What aspects were AI-assisted (architecture, debugging, code review, optimization)
    - Key improvements suggested by AI
    - Screenshots/logs of AI interactions (at least 3 examples)
- (Optional) short screen recording / screenshots

---

## 📊 Evaluation Criteria

### Original Criteria (From Base Requirements)

- Correctness of gameplay rules and RTDB transactions
- Realtime sync reliability (claim/solve consistency)
- UI clarity + responsiveness (portrait split arenas + overlay UX)
- Simulation mode usefulness (bots behave and commit properly)
- Code quality (structure, naming, maintainability)
- Handling of edge cases (expired claims, invalid moves, unreachable)

### Additional Grading Breakdown (Total: 100 points)

**1. Core Functionality (40 points)**

- ✅ Game mechanics work correctly (10 pts)
- ✅ Tower claiming & solving with transactions (10 pts)
- ✅ Real-time synchronization across devices (10 pts)
- ✅ Timer and match lifecycle (5 pts)
- ✅ Auto-generation of new towers (5 pts)

**2. Algorithm Implementation (15 points)**

- ✅ BFS optimal solver correctness (10 pts)
- ✅ Performance & edge case handling (5 pts)

**3. AFK Detection System (15 points)**

- ✅ Player activity tracking (5 pts)
- ✅ Auto-release of claimed towers (5 pts)
- ✅ AFK indicators in UI (3 pts)
- ✅ Player statistics tracking (2 pts)

**4. Architecture & Code Quality (15 points)**

- ✅ Clean Architecture implementation (5 pts)
- ✅ GetX state management proper usage (5 pts)
- ✅ Code organization and readability (3 pts)
- ✅ Error handling and edge cases (2 pts)

**5. AI Usage & Review (10 points)**

- ✅ AI_USAGE.md documentation quality (3 pts)
- ✅ Evidence of AI-assisted development (3 pts)
- ✅ Implementation of AI-suggested improvements (4 pts)

**6. Simulation Mode (5 points)**

- ✅ Bot implementation and behavior (3 pts)
- ✅ Multi-bot coordination testing (2 pts)

**Bonus Points (up to +10):**

- (+5) Advanced BFS reachability check for "unreachable" detection
- (+3) Cloud Functions for match management
- (+2) Beautiful UI/UX with animations
- (+5) Comprehensive Firebase Security Rules
- (+3) Unit tests for solver algorithm
- (+2) Integration tests for Firebase transactions

---

## 📞 Support & Questions

If you have technical questions or need clarification:

- Email: `studyosystemio@gmail.com`
- Whatsapp: `wa.me/6285733571682`
- Subject line: `[Question] Flutter Tower Challenge - [Brief Topic]`

**Response Time:** Within 24-48 hours

---

## ⚖️ Academic Integrity

- You MUST use AI tools (this is a requirement, not cheating)
- Document your AI usage honestly
- Write your own code (AI-assisted is fine, copy-paste from others is not)
- Collaboration is allowed for discussion, but submit individual work
- Plagiarism will result in automatic failure