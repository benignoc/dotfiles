-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This variable will hold the configuration
local config = wezterm.config_builder()

-- Font and size
config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 14

-- Remove the tabs from the windows.
config.enable_tab_bar = false

-- Removing the windows decorations, but still allowing resize.
-- If title needed switch for "TITLE | RESIZE"
config.window_decorations = "RESIZE"
-- Other window settings
-- config.window_background_opacity = 0.8
-- config.macos_window_background_blur = 10

config.color_scheme = "GruvboxDark"
-- keep adding configuration options here

-- Finally, return the configuration to wezterm:
return config
