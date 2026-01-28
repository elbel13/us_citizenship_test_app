# Accessibility Improvements

This document tracks planned accessibility enhancements for the US Citizenship Test App.

## Current Implementation

### Word-by-Word Feedback 
The app now displays word-level feedback in reading and writing practice screens using:
- **Colors**: Green (correct), Red (wrong), Gray (missing), Orange (added)
- **Icons**: Checkmark, X, Minus, Plus
- **Tooltips**: Descriptive messages on hover/long-press

## Planned Enhancements

### Color Blindness Support
**Priority**: High  
**Status**: Planned

Approximately 8% of men and 0.5% of women have some form of color vision deficiency. The current color scheme (green/red/orange/gray) may be difficult for users with:
- Protanopia (red-blind)
- Deuteranopia (green-blind)  
- Tritanopia (blue-blind)

**Proposed Solutions**:
1. **Pattern overlays**: Add diagonal stripes, dots, or other patterns to color backgrounds
2. **Shape variation**: Use different chip shapes (rounded, square, hexagonal) for each diff type
3. **Color scheme option**: Allow users to select from colorblind-friendly palettes:
   - Blue/Orange scheme (safer for most types)
   - High-contrast black/white mode
4. **Text labels**: Add small text labels ("Correct", "Wrong", "Missing", "Added") inside or below each chip
5. **Settings toggle**: "High Contrast Mode" or "Colorblind Mode" option

### Screen Reader Support
**Priority**: Medium  
**Status**: Planned

Improve compatibility with screen readers (TalkBack on Android, VoiceOver on iOS):
- Add semantic labels to all interactive elements
- Ensure word diff chips are readable by screen readers
- Provide audio feedback for correct/incorrect answers
- Add descriptive announcements for navigation changes

### Font Size Customization
**Priority**: Medium  
**Status**: Planned

Allow users to adjust text size for:
- Question text
- Answer options
- Feedback messages
- Word diff display

### High Contrast Mode
**Priority**: Medium  
**Status**: Planned

Implement a high-contrast theme option for users with:
- Low vision
- Light sensitivity
- Difficulty reading text in current color scheme

### Keyboard Navigation
**Priority**: Low  
**Status**: Planned

For users who:
- Use external keyboards
- Have motor impairments
- Prefer keyboard shortcuts

Implement:
- Tab navigation through all interactive elements
- Enter/Space to activate buttons
- Arrow keys for navigation
- Keyboard shortcuts for common actions

## Testing Plan

Before implementing accessibility features:
1. Test with actual users who have disabilities
2. Use accessibility testing tools (Flutter's built-in tools, axe DevTools)
3. Test with screen readers enabled
4. Validate color contrast ratios (WCAG AA/AAA standards)
5. Test with colorblind simulation tools

## Resources

- [Flutter Accessibility Documentation](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://m3.material.io/foundations/accessible-design/overview)
- [Color Blind Awareness](https://www.colourblindawareness.org/)

## Contributions

If you have accessibility needs or suggestions, please open an issue on GitHub or contact the maintainer.

---

*Last updated: January 27, 2026*
