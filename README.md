# WilduTools

A comprehensive World of Warcraft addon providing UI enhancements, automation features, and quality-of-life improvements.

## Features

### UI Enhancements (WilduUI)
- **Target Range Indicator**: Display exact distance to target with class-colored range indicators
- **Mountable Area Indicator**: Shows when you can mount in your current location
- **Spell on Cooldown Indicator**: Displays spell icon when you try to cast while on cooldown
- **Crosshair**: Customizable class-colored crosshair overlay
- **Combat Indicators**: Visual indicators for player and target combat status

### Automation
- **Auto-Gossip**: Automatically select gossip options when only one is available
- **Auto-Accept Role**: Automatically accept role check popups
- **Auto-Accept Group Invites**: Automatically accept group invitations
- **Druid Form Preservation**: Maintains druid forms during combat
- **Update Target Macro (UTM)**: Quickly create and update targeting macros

### Quality of Life
- **Action Bar Enhancements**: Disable mouse interaction, force show all bars
- **Blizzard UI Tweaks**: Various improvements to default UI elements
- **CVars Management**: Automated CVar settings on login
- **Cooldown Manager**: Enhanced cooldown display management
- **Minimap Improvements**: Customizable minimap button and behavior

## Code Structure

The addon has been refactored for better maintainability and modularity:

```
!WilduTools/
├── !WilduTools.lua          # Main entry point and orchestration
├── !WilduTools.toc          # Addon manifest
│
├── core/                    # Core functionality
│   ├── config.lua          # Default settings and configuration
│   ├── debug.lua           # Debug system with timing and profiling
│   └── api.lua             # Shared utility functions and helpers
│
├── ui/                      # UI components
│   ├── core.lua            # Shared UI helpers (EditMode, positioning, throttling)
│   ├── wildu_ui.lua        # Main WilduUI module (delegates to components)
│   └── components/         # Individual UI feature components
│       ├── range_frame.lua        # Target range indicator
│       ├── mount_indicator.lua    # Mountable area icon
│       ├── spell_on_cd.lua        # Spell cooldown display
│       ├── crosshair.lua          # Crosshair overlay
│       └── combat_indicators.lua  # Combat status icons
│
├── automation/              # Automation features
│   ├── automation.lua      # Gossip, role, and invite automation
│   └── updateTargetMacro.lua # UTM macro system
│
├── modules/                 # Other feature modules
│   ├── actionBars.lua      # Action bar management
│   ├── addons.lua          # Addon integration and scaling
│   ├── control_behavior.lua # Control behavior modifications
│   ├── cooldownManager.lua # Cooldown display management
│   ├── cvars.lua           # CVar management
│   ├── minimap.lua         # Minimap customization
│   ├── nameplates.lua      # Nameplate modifications
│   ├── ui.lua              # Blizzard UI enhancements
│   ├── wildu_settings.lua  # Settings registration and layout
│   └── Wildu_SettingControls.lua # Settings control mixins
│
├── libs/                    # Third-party libraries
│   ├── Ace3/               # Ace3 framework
│   ├── LibEditMode/        # EditMode integration
│   ├── LibRangeCheck-3.0-WildFork/ # Range detection
│   └── ...                 # Other libraries
│
└── Media/                   # Media assets
    ├── Art/                # Textures and borders
    ├── Icons/              # Icon assets
    └── SettingsPreview/    # Settings preview images
```

## Module System

All modules follow a consistent pattern:

```lua
local _, ns = ...

--- Module Name
--- Description of what this module does
local ModuleName = {}
ns.ModuleName = ModuleName

-- Module implementation

return ModuleName
```

### Key Modules

#### Core Modules

- **config.lua**: Contains default settings, saved variable structure, and constants
- **debug.lua**: Comprehensive debugging with timers, event tracking, and performance profiling
- **api.lua**: Shared utility functions used across the addon

#### UI Modules

- **ui/core.lua**: Provides shared helpers for all UI components:
  - `LoadFrameConfig()`: Load frame configuration with fallbacks
  - `ApplyFramePosition()`: Position frames with EditMode support
  - `RegisterEditModeCallbacks()`: Handle EditMode integration
  - `CreateThrottledUpdate()`: Throttle frame update callbacks
  - `CreateTickerUpdate()`: Create repeating ticker updates
  - `ApplyVisibilityDriverToFrame()`: Manage visibility state drivers

- **ui/wildu_ui.lua**: Main WilduUI API that delegates to component modules

#### Automation Modules

- **automation/automation.lua**: Handles automated interactions:
  - Gossip automation with NPC-specific handling
  - Auto-accept role checks
  - Auto-accept group invites
  - Druid form preservation

- **automation/updateTargetMacro.lua**: UTM system for creating targeting macros

## Development

### Adding a New UI Component

1. Create a new file in `ui/components/` (e.g., `my_feature.lua`)
2. Follow the module pattern with proper LuaDoc
3. Use helpers from `ui/core.lua` for EditMode integration
4. Add the component to `!WilduTools.toc` in the UI Components section
5. Add initialization function to `ui/wildu_ui.lua`

### LuaDoc Standards

All public functions should include LuaDoc comments:

```lua
---Function description
---@param paramName type Description of parameter
---@param optionalParam? type Optional parameter (note the ?)
---@return type Description of return value
function Module:FunctionName(paramName, optionalParam)
    -- Implementation
end
```

### Naming Conventions

- **Modules**: PascalCase (e.g., `WilduUI`, `Automation`)
- **Local variables**: snake_case (e.g., `local frame_config`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `DEFAULT_SCALE`)
- **Private functions**: snake_case with local (e.g., `local function update_frame()`)
- **Public functions**: PascalCase or camelCase (e.g., `Module:Initialize()`)

### Combat Lockdown

Always check for combat when:
- Modifying action bars
- Changing secure frames
- Registering state drivers

Use `InCombatLockdown()` and defer operations until `PLAYER_REGEN_ENABLED` when necessary.

## Slash Commands

- `/wildutools` or `/wt` - Open settings panel
- `/utm` - Update Target Macro utilities
- `/ccb` - Open Click Cast Binding interface
- `/kb` - Open Quick Keybind Mode
- `/wildudebug` - Debug commands (timer list, events list, spike trace, report)

## Credits

- **Author**: Wildu
- **Libraries**: Ace3, LibEditMode, LibRangeCheck-3.0, LibSharedMedia-3.0, LibDataBroker, LibDBIcon

## License

All rights reserved by the author.
