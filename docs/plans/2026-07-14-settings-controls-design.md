# Settings controls design

The dashboard trend chart gets a persisted `showsTrendChart` preference in `AppSettings`. It defaults to enabled so an upgrade preserves the current dashboard, appears with the other menu-bar presentation settings, and conditionally inserts the existing chart without changing its data lifecycle.

The three independent weight inputs become one partition control. Two integer boundaries split a fixed 0–100 track into IQ, cost, and duration segments. IQ equals the first boundary, cost is the distance between boundaries, and duration is the remaining distance to 100. The representation makes an invalid total impossible. Changes persist and recalculate rankings immediately; a reset button restores 50 / 25 / 25.

SwiftUI `Slider` and AppKit `NSSlider` each expose one value and one thumb, so the partition control is drawn in SwiftUI. It keeps native conventions through system colors, a drag gesture, one-percent rounding, and adjustable accessibility actions for both boundaries. Tests cover the new preference's default and persistence; the existing ranking tests continue to verify valid weight handling.
