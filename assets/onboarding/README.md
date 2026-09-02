# Onboarding assets

Drop your real photos and videos here. The app will use them automatically.

**File names the app looks for (if present):**

- `welcome.jpg` or `welcome.png` — page 1
- `study.jpg` / `study.mp4` — page 2 (students)
- `business.jpg` / `business.mp4` — page 3 (small business)
- `create.jpg` — page 4 (creators)
- `everyday.mp4` — page 5 (video montage of all uses)

**Rules:**
- Images: JPG/PNG/WebP, ~1080×1440 works best
- Videos: MP4 H.264, 720p, < 8 MB each, muted looping
- If a file is missing, the gold placeholder with icon shows — no crash

**To wire a new file:** uncomment the `imageAsset` / `videoAsset` line
in `lib/screens/onboarding_screen.dart` for that page.

Example:
```dart
const _OnboardingPage(
  title: 'Study & understand',
  icon: Icons.school_rounded,
  accent: Color(0xFF2E7D32),
  imageAsset: 'assets/onboarding/study.jpg',
  videoAsset: 'assets/onboarding/study.mp4', // video wins if both set
),
```
