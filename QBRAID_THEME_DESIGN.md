# qBraid Theme Design Specification for JupyterLab

## Overview
Transform JupyterLab's appearance to match qBraid's modern, futuristic design language.
Design philosophy: **Wallet-style minimalism with dashboard color hints** - clean, professional coding environment.

---

## Color System

### Dark Mode (Primary)

#### Backgrounds
| Token | Value | Usage |
|-------|-------|-------|
| `--bg-deepest` | `#0a0a0a` | Main app background |
| `--bg-sidebar` | `#111111` | Sidebar background |
| `--bg-card` | `#141414` | Cards, panels, cells |
| `--bg-elevated` | `#1a1a1a` | Elevated surfaces, dropdowns |
| `--bg-hover` | `#1f1f1f` | Hover states |
| `--bg-active` | `#262626` | Active/pressed states |

#### Borders
| Token | Value | Usage |
|-------|-------|-------|
| `--border-subtle` | `#1f1f1f` | Very subtle dividers |
| `--border-default` | `#262626` | Default borders |
| `--border-strong` | `#333333` | Emphasized borders |
| `--border-active` | `#14b8a6` | Active/selected state |

#### Text
| Token | Value | Usage |
|-------|-------|-------|
| `--text-primary` | `#ededed` | Primary text |
| `--text-secondary` | `#a3a3a3` | Secondary text |
| `--text-muted` | `#737373` | Muted/disabled text |
| `--text-inverse` | `#0a0a0a` | Text on light backgrounds |

#### Brand & Accent
| Token | Value | Usage |
|-------|-------|-------|
| `--brand-primary` | `#10b981` | Primary actions, active states |
| `--brand-primary-hover` | `#059669` | Primary hover |
| `--brand-secondary` | `#8b5cf6` | Brand accent, special highlights |
| `--brand-secondary-hover` | `#7c3aed` | Secondary hover |

#### Semantic Colors
| Token | Value | Usage |
|-------|-------|-------|
| `--success` | `#22c55e` | Success states |
| `--warning` | `#f59e0b` | Warning states |
| `--error` | `#ef4444` | Error states |
| `--info` | `#3b82f6` | Info states |

#### Syntax Highlighting (Code)
| Token | Value | Usage |
|-------|-------|-------|
| `--syntax-keyword` | `#c084fc` | Keywords (import, def, class) |
| `--syntax-string` | `#4ade80` | Strings |
| `--syntax-number` | `#fbbf24` | Numbers |
| `--syntax-function` | `#60a5fa` | Functions |
| `--syntax-comment` | `#6b7280` | Comments |
| `--syntax-operator` | `#f472b6` | Operators |
| `--syntax-variable` | `#e5e7eb` | Variables |
| `--syntax-builtin` | `#2dd4bf` | Built-ins |

---

## Spacing & Sizing

| Token | Value | Usage |
|-------|-------|-------|
| `--radius-sm` | `4px` | Small elements, tags |
| `--radius-md` | `6px` | Buttons, inputs |
| `--radius-lg` | `8px` | Cards, panels |
| `--radius-xl` | `12px` | Modals, large cards |
| `--spacing-xs` | `4px` | Tight spacing |
| `--spacing-sm` | `8px` | Small spacing |
| `--spacing-md` | `12px` | Medium spacing |
| `--spacing-lg` | `16px` | Large spacing |
| `--spacing-xl` | `24px` | Extra large spacing |

---

## Component Specifications

### 1. Cells (Code/Markdown)
- Background: `#141414`
- Border: `1px solid #262626`
- Border radius: `8px`
- Active cell: Left accent bar `3px` in `#10b981`
- Active border: `#14b8a6`
- Cell spacing: `8px` between cells
- Input prompt color: `#6b7280` (muted)

### 2. Toolbar
- Background: `#111111`
- Border bottom: `1px solid #262626`
- Button hover: `#1f1f1f`
- Active button: `#262626` with `#10b981` accent
- Icon color: `#a3a3a3`, hover: `#ededed`

### 3. Menu Bar
- Background: `#0a0a0a`
- Text: `#a3a3a3`
- Hover: `#1f1f1f` background
- Active: `#262626` background
- Dropdown: `#141414` with `#262626` border, `8px` radius

### 4. Sidebar
- Background: `#111111`
- Border right: `1px solid #1f1f1f`
- Item hover: `#1a1a1a`
- Item active: `#1f1f1f` with left accent `#10b981`
- Icon color: `#737373`, active: `#ededed`

### 5. Tabs
- Background: `#0a0a0a`
- Tab hover: `#141414`
- Active tab: `#141414` with bottom border `#10b981`
- Close button: `#737373`, hover: `#ededed`

### 6. File Browser
- Background: `#111111`
- Row hover: `#1a1a1a`
- Selected row: `#1f1f1f` with left accent
- File icon: `#737373`
- Folder icon: `#a3a3a3`

### 7. Dialogs/Modals
- Overlay: `rgba(0, 0, 0, 0.7)`
- Background: `#141414`
- Border: `1px solid #262626`
- Border radius: `12px`
- Primary button: `#10b981` bg, `#ffffff` text
- Secondary button: `transparent` bg, `#262626` border

### 8. Scrollbars
- Track: `#141414`
- Thumb: `#333333`
- Thumb hover: `#404040`
- Width: `8px`
- Border radius: `4px`

### 9. Status Bar
- Background: `#0a0a0a`
- Border top: `1px solid #1f1f1f`
- Text: `#737373`
- Active indicators: `#10b981`

---

## Effects

### Shadows
- `--shadow-sm`: `0 1px 2px rgba(0, 0, 0, 0.3)`
- `--shadow-md`: `0 4px 6px rgba(0, 0, 0, 0.4)`
- `--shadow-lg`: `0 10px 15px rgba(0, 0, 0, 0.5)`
- `--shadow-glow`: `0 0 20px rgba(16, 185, 129, 0.15)` (for focus states)

### Transitions
- Default: `150ms ease`
- Hover: `200ms ease`
- Modal: `300ms cubic-bezier(0.4, 0, 0.2, 1)`

---

## Files to Modify

### Tier 1: Foundation
- [ ] `packages/theme-dark-extension/style/variables.css`

### Tier 2: Core Experience
- [ ] `packages/cells/style/widget.css`
- [ ] `packages/cells/style/inputarea.css`
- [ ] `packages/cells/style/collapser.css`
- [ ] `packages/notebook/style/base.css`
- [ ] `packages/notebook/style/toolbar.css`

### Tier 3: Layout
- [ ] `packages/application/style/menus.css`
- [ ] `packages/application/style/tabs.css`
- [ ] `packages/application/style/sidebar.css`
- [ ] `packages/application/style/dockpanel.css`

### Tier 4: Components
- [ ] `packages/apputils/style/dialog.css`
- [ ] `packages/apputils/style/toolbar.css`
- [ ] `packages/filebrowser/style/base.css`
- [ ] `packages/statusbar/style/base.css`

### Tier 5: Polish
- [ ] `packages/codemirror/style/base.css`
- [ ] `packages/launcher/style/base.css`
- [ ] `packages/running/style/base.css`
- [ ] `packages/apputils-extension/style/scrollbar.raw.css`

---

## Reference
- qBraid Account Screenshots: `/account-screenshots/`
- qBraid Design Tokens: `/Users/kanav/qBraid_repositories/master_jlab_extension/qbraid-account/src/app/globals.css`
