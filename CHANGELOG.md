# !WilduTools

## [1811b09](https://github.com/lemieszek/WilduTools/tree/1811b0997de0d577ab45914b0ab7935fbffb4098) (2025-11-19)
[Full Changelog](https://github.com/lemieszek/WilduTools/commits/1811b0997de0d577ab45914b0ab7935fbffb4098) 

- Core Refactor & Best Practices  
    Refactored all UI indicator code for maintainability and performance.  
    Introduced reusable helper functions for frame creation, positioning, throttling, and settings.  
    Reduced code duplication and made new feature addition much faster and error-proof.  
    All database settings preserved; module remains 100% backward compatible.  
    Indicator Enhancements & New Features  
    Added dynamic "Player in Combat" and "Target in Combat" icons with automatic toggling and EditMode support.  
    Added EditMode preview for all indicators (show at full alpha during EditMode even if not otherwise visible).  
    Indicators now always stay hidden when option is disabled (no more ghost icons in EditMode!).  
    Crosshair Upgrades  
    Crosshair now supports:  
    Color Sliders: Red, Green, Blue sliders for custom color (enabled only when "Class colored" is unchecked).  
    "Class colored" switch: Toggles between class and custom color.  
    Horizontal Lock: New checkbox to lock the crosshair to screen center horizontally.  
    Visibility Dropdown: Choose when the crosshair is shown: Always, In Combat, In Instance, In Combat + In Instance.  
    Scaling Fix: Properly applies scaling for the crosshair from config at startup.  
    Other Tweaks & Bugfixes  
    Disabled indicators are truly hidden in EditMode.  
    Scaling now always applies to the crosshair at initialization.  
    Added/fixed defensive checks to eliminate Lua errors on frame load/settings.  
- fix multiple and not hiding crosshairs  
- spellOnCd and crosshair  
- Addon cleanup of deprecated/unused functions  
- Add debugging module for performance debugging  
- Initial release  
