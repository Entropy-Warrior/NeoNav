# Features

Here's what this thing does. Nothing fancy. Just the essentials. If you're looking for AI-powered bookmark suggestions or social sharing, you're in the wrong place. This is a floating strip that shows your bookmarks. That's it. And honestly, that's all you need.

## Core Features

### Floating Bookmark Strip
- Always-visible window that stays on top
- Works across all Mission Control spaces
- Drag from left handle to reposition
- Resize to adjust grid layout (1-8 icons per row)
- Position automatically saved

### Bookmark Management
- **Add**: Click + button, enter URL and title
- **Edit**: Select bookmark to modify details
- **Delete**: Select and click - button
- **Reorder**: Drag bookmarks in list
- **Drag URLs**: Drop URLs from browser to add instantly

### Automatic Favicon Fetching
- Multi-strategy approach (HTML parsing → standard locations → Google service)
- >95% success rate
- 50MB cache (memory + disk)
- Standardized to 128x128 PNG
- Background fetching (non-blocking)

### Custom Icons
- Drag-and-drop image files onto bookmark icons
- Real-time preview before applying
- Supports PNG, JPG, GIF, TIFF, BMP
- Manual icons never auto-updated

## User Interface

### Main Window
- Split view: list on left, details on right
- Icon previews in list
- Large icon display in detail view
- Editable title and URL fields

### Floating Strip
- 70x70 pixel icons
- Semi-transparent background
- Hover effects
- Click to open in default browser

## Data Management

- All data stored locally on your Mac
- Bookmarks: `~/Library/Application Support/NeoNav/bookmarks.json`
- Preferences: `~/Library/Application Support/NeoNav/preferences.json`
- Window state: macOS UserDefaults
- No data transmitted to external servers

## Platform Integration

- Native macOS appearance (dark mode support)
- Multi-monitor support
- Window position persistence
- Drag-and-drop from Finder and browsers
