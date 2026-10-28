# NotePad++ for Android

## Context

Build a mobile text editor for Android phones inspired by the core workflow of
NotePad++. The app should make it easy to work with ordinary text files while
also supporting notes managed inside the app.

## Role

Act as a senior Android engineer and product designer. Create a reliable,
accessible, touch-friendly app with clear separation between public files and
notes stored by the app.

## Action

Implement the following capabilities:

- Open public files available through Android's document/file picker.
- Edit text with standard mobile editing interactions.
- Save changes back to public files, including appropriate handling of file
	permissions and save errors.
- Create, read, update, and delete notes stored in the app's internal SQLite
	database.
- Allow each note to have tags represented as key-value pairs.
- Provide a way to browse, search, and filter saved notes by their content or
	tags.
- Preserve unsaved edits when the app is backgrounded or recreated whenever
	Android lifecycle constraints allow it.

Use Android platform conventions, persist data safely, and request only the
permissions the app actually needs.

## Format

Deliver a complete Android project with:

- A usable first screen for opening public files or browsing internal notes.
- Clear empty, loading, error, and unsaved-change states.
- Reusable UI components and a maintainable data layer.
- Tests for file operations, note persistence, tag handling, and search/filter
	behavior.
- A README covering setup, build, and the supported workflows.

The implementation must build successfully and should avoid losing user data.

## Tone

Keep the experience focused, practical, and familiar to users of a lightweight
text editor. Prefer simple controls, readable typography, and concise feedback
over decorative UI.
