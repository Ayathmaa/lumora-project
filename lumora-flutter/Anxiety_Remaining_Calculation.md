# Lumora: Anxiety Remaining (%) Calculation Logic

## The Core Concept
The "Anxiety Remaining" graph in Lumora visualizes the psychological effectiveness of a user's journaling and ERP (Exposure and Response Prevention) sessions. 

Instead of tracking the raw absolute point drop (e.g., dropping 1 point on a 1-10 scale), the algorithm calculates **Proportional Relief**. It determines exactly what percentage of the original anxiety survived the exercise.

## The Formula
For every CBT Journal or ERP Session, the Cloud Function runs the following calculation:
```
(Post-Anxiety / Pre-Anxiety) * 100 = Anxiety Remaining (%)
```

## Why Proportional Relief Matters
Psychologically, going down 1 point from a highly escalated panic state (Level 8) is very different from going down 1 point from a moderate stress state (Level 5). The graph tracks the *relative* impact of the exercise against the intensity of the starting baseline.

### Example A: Moderate Anxiety
A user starts at a Level 5 and finishes at a Level 4.
*   **Formula:** `(4 / 5) * 100` = **80%**
*   **Meaning:** 80% of the anxiety remained after the exercise. The user successfully reduced their anxiety by an impressive **20%** relative to how they were feeling when they started.

### Example B: Severe Anxiety
The next day, the user is in an intense panic. They start at a Level 8 and finish at a Level 7. The absolute difference is still exactly 1 point.
*   **Formula:** `(7 / 8) * 100` = **87.5%**
*   **Meaning:** 87.5% of the anxiety remained. The user only reduced their anxiety by **12.5%** relative to their highly elevated baseline.

Even though both sessions resulted in a raw drop of exactly 1 point, the graph accurately plots Example B slightly higher (87.5%) than Example A (80%). This visually communicates to the user that the exercise was slightly less effective at completely clearing the anxiety when their baseline stress was exponentially higher.

## Daily Aggregation
Because users may log multiple journals or timers entirely within the same calendar day, plotting 5-10 individual data points on a single vertical timeline slice would make the UI incredibly cluttered and unreadable. 

To solve this, the Cloud Server performs daily aggregation:
1. It calculates the `(Post / Pre) * 100` percentage for every single entry that shares the exact same `dateKey`.
2. It adds all the daily percentages together.
3. It divides by the total number of sessions that day to find the true **Daily Average**.
4. Finally, it plots that single clean datapoint on the graph to demonstrate week-over-week emotional progression.