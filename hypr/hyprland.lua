-- Hyprland loads this file when it is started without a config, and it prefers
-- it over hyprland.conf. HyDE loads it too, last, as the override layer below.
-- The block keeps the two apart: hyde.lua sets `hyde` on its first line, so it
-- runs only when this file is the entry point and HyDE has not been loaded.
-- Removing it leaves a session with a cursor and nothing else.
if not hyde then
	local share = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
	local entry = share .. "/hypr/hyde.lua"
	local handle = io.open(entry, "r")
	if not handle then
		error("HyDE is not installed at " .. entry .. ". Run install.sh -r, or point Hyprland at your own config.")
	end
	handle:close()
	dofile(entry)
end

-- Your Hyprland configuration. HyDE never overwrites this file.
--
-- It loads after HyDE's own binds, so settings here take precedence. Replacing
-- a bind needs more than that: see below. HyDE's defaults live in
-- ~/.local/share/hypr/lua/ and are overwritten on every update, so edits there
-- do not survive.
--
-- Adding a keybind:
--
--     hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(hyde.sh.gamelauncher()), {
--         description = "[Utilities] game launcher",
--     })
--
-- Replacing one of HyDE's: bind the same combination again and yours takes
-- over, but copy its flags across as well. A bind counts as the same one only
-- when its flags match, and `description` is not a flag — miss one and both
-- binds stay live on that combination. Copy the whole options table from
-- ~/.local/share/hypr/lua/key_binds.lua and change only what you need:
--
--     hl.bind("F9", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "m")), {
--         locked = true,
--         description = "[Hardware Controls|Audio] un/mute output",
--     })
--
-- Press SUPER + / to see what is actually loaded, your own binds included.
-- The full reference is KEYBINDINGS.md in the HyDE repository.
--
-- Other Lua files next to this one can be pulled in with require("name").

-- ===========================================================================
-- Ported from the pre-HyDE hyprland.conf (git tag: pre-hyde).
--
-- That config was a port of a macOS yabai/skhd setup, and the whole point of
-- it is the two-modifier split:
--
--   macOS cmd -> SUPER  launching, screenshots, clipboard, lock
--   macOS alt -> ALT    every window and workspace operation
--
-- HyDE puts everything on SUPER, so the ALT layer below is additive and does
-- not collide with it. The SUPER binds here do overwrite HyDE's on the same
-- combination; `hyde.binds.dedup` is on, so rebinding replaces rather than
-- stacking, as long as the flags match. None of these carry flags, and neither
-- do HyDE's equivalents.
--
-- ponytail: ALT-as-window-mod shadows GTK/Qt menu mnemonics (Alt+F, Alt+E...).
-- If that bites, change WM_MOD below and the whole layer follows.
-- ===========================================================================

local WM_MOD = "ALT" -- window management
local LAUNCH = "SUPER" -- launching

local terminal = "kitty"
local browser = "google-chrome-stable"

-- ---------------------------------------------------------------------------
-- Look
--
-- HyDE drives border colours from the wallbash palette in dynamic.lua, mapping
-- them to roles (pry4 / 4xa1) that land on lavender for this palette rather
-- than the cyan->magenta gradient the old config used. Setting them here wins,
-- because this file loads after HyDE's own configuration.
-- ---------------------------------------------------------------------------
hl.config(
	{
		-- Pointer tuning. GNOME Settings writes to dconf, which only Mutter
		-- reads, so under Hyprland these are the knobs that take effect.
		-- sensitivity: -1.0 (slowest) .. 1.0 (fastest), 0 = untouched.
		-- accel_profile: flat = raw 1:1, adaptive = libinput's accel curve.
		input = {
			kb_layout = "us",
			follow_mouse = 0,
			sensitivity = 0,
			accel_profile = "flat"
		},
		general = {
			gaps_in = 3,
			gaps_out = 7,
			border_size = 2,
			col = {
				active_border = {colors = {"rgba(2cf9edff)", "rgba(eb46f9ff)"}, angle = 45},
				inactive_border = {colors = {"rgba(003547ff)"}}
			}
		},
		decoration = {
			rounding = 8,
			-- A cyan glow rather than a black drop shadow: at 0x33 it reads as
			-- a rim light on the focused window.
			shadow = {
				enabled = true,
				range = 20,
				color = "rgba(2cf9ed33)"
			}
		}
	}
)

-- ---------------------------------------------------------------------------
-- Workspaces 1-2 on the left monitor, 3-6 on the right.
--
-- Note the call shape: hl.workspace_rule takes ONE table with the workspace as
-- a field. The hl.workspace_rule("1", {...}) form raises no error and registers
-- nothing, so a rule written that way goes missing silently.
-- ---------------------------------------------------------------------------
hl.workspace_rule({workspace = "1", monitor = "HDMI-A-1", default = true})
hl.workspace_rule({workspace = "2", monitor = "HDMI-A-1"})
hl.workspace_rule({workspace = "3", monitor = "DP-2", default = true})
hl.workspace_rule({workspace = "4", monitor = "DP-2"})
hl.workspace_rule({workspace = "5", monitor = "DP-2"})
hl.workspace_rule({workspace = "6", monitor = "DP-2"})

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Hyprland's `fullscreen` dispatcher toggles; fullscreen_state sets an absolute
-- value, so the toggle has to be rebuilt. Internal state 1 is maximise-inside-
-- gaps and 2 is true fullscreen, matching `fullscreen, 1` and `fullscreen, 0`
-- in the old config.
local function toggle_fullscreen(state)
	return function()
		local win = hl.get_active_window()
		if not win then
			return
		end
		local current = tonumber(win.fullscreen) or 0
		local next_state = (current == state) and 0 or state
		hl.dispatch(hl.dsp.window.fullscreen_state({internal = next_state, client = next_state, window = win}))
	end
end

local shot_dir = "~/Pictures/Screenshots"

-- tee keeps a file on disk while wl-copy takes the same bytes, which is what
-- the old binds did. exec runs through /bin/sh, so the pipeline and the $(date)
-- substitution are evaluated at press time.
local function screenshot(region)
	local grab = region and 'grim -g "$(slurp)"' or "grim"
	return hl.dsp.exec_cmd(
		"mkdir -p " ..
			shot_dir ..
				" && " .. grab .. " - | tee " .. shot_dir .. '/$(date +%Y-%m-%d_%H-%M-%S).png | wl-copy'
	)
end

local _F

-- ---------------------------------------------------------------------------
-- Launch layer -- SUPER
-- ---------------------------------------------------------------------------

_F = {description = "[Launch] terminal"}
hl.bind(LAUNCH .. " + Return", hl.dsp.exec_cmd(terminal), _F)

_F = {description = "[Launch] browser"}
hl.bind(LAUNCH .. " + SHIFT + Return", hl.dsp.exec_cmd(browser), _F)

-- File explorer moved off HyDE's SUPER + E. Rebinding alone is not enough:
-- hyde.binds.dedup only replaces a bind on the *same* combo, so the original
-- SUPER + E has to be unbound explicitly or it keeps working alongside this
-- one. unbind matches the string the bind was registered with, hence the
-- normalize() call rather than a hand-spelled "SUPER, E".
hl.unbind(hyde.binds.normalize(LAUNCH .. " + E"))

-- yazi, not hyde.config.app.explorer: that variable is
-- `hyde-shell open --fall dolphin file-manager`, so going through it puts
-- Dolphin back as a fallback. The terminal is spelled out for the same reason.
_F = {description = "[Launch] file explorer"}
hl.bind(LAUNCH .. " + F", hl.dsp.exec_cmd("kitty --class yazi -e yazi"), _F)

-- Spotlight. Routed to HyDE's launcher rather than the old wofi call so it
-- picks up the theme.
_F = {description = "[Launch] application launcher"}
hl.bind(LAUNCH .. " + SPACE", hl.dsp.exec_cmd(hyde.sh.menu.apps()), _F)

-- macOS ctrl+cmd+Q
_F = {description = "[Session] lock"}
hl.bind(LAUNCH .. " + CTRL + Q", hl.dsp.exec_cmd(hyde.sh.session.lock()), _F)

_F = {description = "[Session] exit Hyprland"}
hl.bind(LAUNCH .. " + SHIFT + Q", hl.dsp.exit(), _F)

_F = {description = "[Screenshot] region to file and clipboard"}
hl.bind(LAUNCH .. " + SHIFT + 4", screenshot(true), _F)

_F = {description = "[Screenshot] full screen to file and clipboard"}
hl.bind(LAUNCH .. " + SHIFT + 3", screenshot(false), _F)

-- `locked` is not decoration here: HyDE binds Print with locked = true, and a
-- bind only replaces another when its flags match. Without it this registers
-- as a second, separate bind and both fire on one keypress.
_F = {description = "[Screenshot] region to file and clipboard", locked = true}
hl.bind("Print", screenshot(true), _F)

-- Move a window without changing focus order, SUPER + shift + hjkl.
for key, dir in pairs({H = "l", J = "d", K = "u", L = "r"}) do
	_F = {description = "[Window Management] move window " .. dir}
	hl.bind(LAUNCH .. " + SHIFT + " .. key, hl.dsp.window.move({direction = dir}), _F)
end

_F = {description = "[Window Management] drag window"}
hl.bind(LAUNCH .. " + mouse:272", hl.dsp.window.drag(), _F)

_F = {description = "[Window Management] resize window"}
hl.bind(LAUNCH .. " + mouse:273", hl.dsp.window.resize(), _F)

_F = {description = "[Session] reload Hyprland"}
hl.bind("CTRL + ALT + " .. LAUNCH .. " + R", hl.dsp.exec_cmd("hyprctl reload"), _F)

-- ---------------------------------------------------------------------------
-- Window layer -- ALT
-- ---------------------------------------------------------------------------

for key, dir in pairs({H = "left", J = "down", K = "up", L = "right"}) do
	_F = {description = "[Window Management] focus " .. dir}
	hl.bind(WM_MOD .. " + " .. key, hl.dsp.focus({direction = dir}), _F)
end

for key, dir in pairs({H = "l", J = "d", K = "u", L = "r"}) do
	_F = {description = "[Window Management] swap window " .. dir}
	hl.bind(WM_MOD .. " + SHIFT + " .. key, hl.dsp.window.swap({direction = dir}), _F)
end

for i = 1, 6 do
	_F = {description = "[Workspaces] switch to workspace " .. i}
	hl.bind(WM_MOD .. " + " .. i, hl.dsp.focus({workspace = i}), _F)

	_F = {description = "[Workspaces] move window to workspace " .. i}
	hl.bind(WM_MOD .. " + SHIFT + " .. i, hl.dsp.window.move({workspace = i}), _F)
end

_F = {description = "[Workspaces] switch to nearest empty workspace"}
hl.bind(WM_MOD .. " + N", hl.dsp.focus({workspace = "empty"}), _F)

_F = {description = "[Workspaces] move window to nearest empty workspace"}
hl.bind(WM_MOD .. " + SHIFT + N", hl.dsp.window.move({workspace = "empty"}), _F)

_F = {description = "[Window Management] close window"}
hl.bind(WM_MOD .. " + X", hl.dsp.window.close(), _F)

_F = {description = "[Window Management] toggle split direction"}
hl.bind(WM_MOD .. " + E", hl.dsp.layout("togglesplit"), _F)

-- Closest thing to yabai's zoom-parent.
_F = {description = "[Window Management] toggle pseudo tiling"}
hl.bind(WM_MOD .. " + D", hl.dsp.window.pseudo(), _F)

_F = {description = "[Window Management] maximise inside gaps"}
hl.bind(WM_MOD .. " + F", toggle_fullscreen(1), _F)

_F = {description = "[Window Management] true fullscreen"}
hl.bind(WM_MOD .. " + SHIFT + F", toggle_fullscreen(2), _F)

-- Float, half size, centred. Was a `hyprctl --batch "dispatch ..."` string,
-- which the Lua config provider cannot parse (see the minimize binds below);
-- as a Lua function the three steps run in-process, so there is no visible
-- jump through the intermediate sizes either.
--
-- hl.dsp.window.resize takes pixels, not the "50%" the old exact resize used,
-- so the half is computed from the monitor. Dispatchers called from inside a
-- function must be handed to hl.dispatch: calling the builder directly, the
-- way HyDE's own key_binds.lua does, returns nil and dispatches nothing.
local float_half_centred = function()
	hl.dispatch(hl.dsp.window.float({action = "toggle"}))
	if not hl.get_active_window().floating then
		return -- was floating, is now tiled: nothing to size or centre
	end
	local m = hl.get_active_monitor()
	hl.dispatch(hl.dsp.window.resize({x = math.floor(m.width / m.scale / 2), y = math.floor(m.height / m.scale / 2)}))
	hl.dispatch(hl.dsp.window.center())
end

_F = {description = "[Window Management] float window centred at half size"}
hl.bind(WM_MOD .. " + T", float_half_centred, _F)

-- Float every window here, or tile them all again if they are already floating.
-- The Lua API has no workspaceopt dispatcher, so this walks the workspace
-- instead. Unlike workspaceopt allfloat it sets no mode on the workspace:
-- windows opened afterwards tile as usual.
local toggle_all_float = function()
	local windows = hl.get_workspace_windows(hl.get_active_workspace().id)
	local any_tiled = false
	for _, w in ipairs(windows) do
		if not w.floating then
			any_tiled = true
		end
	end
	for _, w in ipairs(windows) do
		hl.dispatch(hl.dsp.window.float({action = any_tiled and "on" or "off", window = "address:" .. w.address}))
	end
end

_F = {description = "[Window Management] float every window on this workspace"}
hl.bind("CTRL + ALT + D", toggle_all_float, _F)

-- Resize, held. `repeating` is the flag HyDE uses for its own held binds and is
-- the Lua equivalent of `binde`.
for key, delta in pairs({H = {-40, 0}, L = {40, 0}, K = {0, -40}, J = {0, 40}}) do
	_F = {description = "[Window Management] resize window", repeating = true}
	hl.bind("CTRL + ALT + " .. key, hl.dsp.window.resize({x = delta[1], y = delta[2], relative = true}), _F)
end

-- Gaps. State lives in gaps.sh, which drives hyprctl keyword directly and so
-- is unaffected by the move to the Lua configuration.
_F = {description = "[Window Management] toggle gaps"}
hl.bind(WM_MOD .. " + A", hl.dsp.exec_cmd("~/.config/hypr/gaps.sh toggle"), _F)

_F = {description = "[Window Management] increase gaps", repeating = true}
hl.bind(WM_MOD .. " + G", hl.dsp.exec_cmd("~/.config/hypr/gaps.sh +"), _F)

_F = {description = "[Window Management] decrease gaps", repeating = true}
hl.bind(WM_MOD .. " + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/gaps.sh -"), _F)

-- Minimize, by way of a named special workspace. Hyprland has no iconified
-- window state, so "minimized" is a scratchpad the window is parked on: hidden
-- until the overlay is toggled, then pulled back out onto a real workspace.
--
-- The name keeps this separate from HyDE's own scratchpad on SUPER + S, which
-- uses the unnamed `special`.
--
-- These must use the hl.dsp dispatchers, not exec_cmd("hyprctl dispatch ..."):
-- under the Lua config provider `hyprctl dispatch` evaluates its argument as
-- Lua, so a bare dispatcher name is a syntax error at keypress time and the
-- bind silently does nothing.
_F = {description = "[Window Management] minimize window to the scratchpad"}
hl.bind(WM_MOD .. " + M", hl.dsp.window.move({workspace = "special:minimized", follow = false}), _F)

-- The special workspace name goes in positionally. toggle_special({name = ...})
-- is accepted but ignores the name and opens the unnamed `special` instead.
_F = {description = "[Window Management] show/hide minimized windows"}
hl.bind(WM_MOD .. " + SHIFT + M", hl.dsp.workspace.toggle_special("minimized"), _F)

-- Restore: `e+0` is the focused monitor's normal workspace, so the window lands
-- wherever you are rather than on the one it was minimized from. The overlay
-- closes on its own once the last window leaves.
_F = {description = "[Window Management] restore minimized window to this workspace"}
hl.bind(WM_MOD .. " + CTRL + M", hl.dsp.window.move({workspace = "e+0"}), _F)
