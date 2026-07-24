--#######################
--## MONITORS / WORKSPACES
--#######################

-- Host-specific monitor + workspace layout, inline via a hostname check.
-- (hyprlang couldn't do conditionals; Lua can, so this stays in one file.)
local function hostname()
    local f = io.open("/etc/hostname")
    if not f then return "" end
    local h = f:read("*l") or ""
    f:close()
    return h
end

if hostname() == "msi-laptop" then
    -- msi-laptop: static internal panel + generic fallback, 5 workspaces on
    -- whatever display is default (no monitor: binding).
    hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "auto", scale = 1 })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
    hl.workspace_rule({ workspace = "1", persistent = true, default = true })
    for i = 2, 5 do
        hl.workspace_rule({ workspace = tostring(i), persistent = true })
    end
else
    -- louqe-pc desktop: dual monitor, 1-5 on DP-1, 6-10 on HDMI-A-1.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
    for i = 1, 5 do
        hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", persistent = true })
    end
    for i = 6, 10 do
        hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", persistent = true })
    end
end

--##################
--## MY PROGRAMS ###
--##################

-- See https://wiki.hyprland.org/Configuring/Keywords/

-- Set programs that you use
local terminal = "ghostty"
local fileManager = "dolphin"
local menu = "fuzzel"
local browser = "google-chrome-stable --disable-features=WaylandWpColorManagerV1"
local exitSession = "systemctl --user stop hyprland-session.target; hyprctl dispatch 'hl.dsp.exit()'"

--################
--## AUTOSTART ###
--################

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

-- exec-once = $terminal
-- exec-once = nm-applet &
-- exec-once = waybar & hyprpaper & firefox
hl.env("SSH_AUTH_SOCK", "$XDG_RUNTIME_DIR/gcr/ssh")

--############################
--## ENVIRONMENT VARIABLES ###
--############################

-- See https://wiki.hyprland.org/Configuring/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("TERMINAL", "ghostty")
hl.env("EDITOR", "hx")
hl.env("VISUAL", "hx")

--##################
--## PERMISSIONS ###
--##################

-- See https://wiki.hyprland.org/Configuring/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- ecosystem {
--   enforce_permissions = 1
-- }

-- permission = /usr/(bin|local/bin)/grim, screencopy, allow
-- permission = /usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow
-- permission = /usr/(bin|local/bin)/hyprpm, plugin, allow

--####################
--## LOOK AND FEEL ###
--####################

-- Refer to https://wiki.hyprland.org/Configuring/Variables/

-- https://wiki.hyprland.org/Configuring/Variables/#general

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 10,
    bezier = "default",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 5.39,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.79,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4.1,
    bezier = "easeOutQuint",
    style = "popin 87%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.49,
    bezier = "linear",
    style = "popin 87%",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 1.73,
    bezier = "almostLinear",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.46,
    bezier = "almostLinear",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3.03,
    bezier = "quick",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.81,
    bezier = "easeOutQuint",
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
    style = "fade",
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.5,
    bezier = "linear",
    style = "fade",
})
hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 1.79,
    bezier = "almostLinear",
})
hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 1.39,
    bezier = "almostLinear",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 1.94,
    bezier = "almostLinear",
    style = "fade",
})
hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 1.21,
    bezier = "almostLinear",
    style = "fade",
})
hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 1.94,
    bezier = "almostLinear",
    style = "fade",
})

hl.layer_rule({
    name = "no-anim-quick-ask",
    match = {
        namespace = "quick-ask",
    },
    no_anim = true,
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
-- 0.55 has no gesture "dispatcher" field; `action` takes a string (workspace,
-- special, resize, …) or a Lua function. Original hyprlang ran a script via
-- `dispatcher, exec`, so we call the (still-installed) scripts from a function.
-- (Native alternative: action = "special", workspace = "magic".)
hl.gesture({
    fingers = 3,
    direction = "down",
    action = function() hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/show_special_workspace.sh")) end,
})
hl.gesture({
    fingers = 3,
    direction = "up",
    action = function() hl.dispatch(hl.dsp.exec_cmd("~/.config/hypr/hide_special_workspace.sh")) end,
})

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("quick-ask"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(exitSession))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(exitSession))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + K", hl.dsp.layout("swapsplit"))
hl.bind(mainMod .. " + R", hl.dsp.layout("movetoroot"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd("loginctl lock-session"))

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("dpms-off"))

hl.bind(mainMod .. " + SHIFT + O", hl.dsp.dpms({ action = "on" }))

hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/screenshot.sh"))

hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/toggle_recording.sh"))

hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/random-wallpaper.sh"))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + KP_1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + KP_2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + KP_3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + KP_4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + KP_5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + KP_6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + KP_7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + KP_8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + KP_9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + KP_0", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + KP_End", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + KP_Down", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + KP_Page_Down", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + KP_Left", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + KP_Begin", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + KP_Right", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + KP_Home", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + KP_Up", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + KP_Page_Up", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + KP_Insert", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + KP_1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + KP_2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + KP_3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + KP_4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + KP_5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + KP_6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + KP_7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + KP_8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + KP_9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + KP_0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + KP_End", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + KP_Down", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + KP_Page_Down", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + KP_Left", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + KP_Begin", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + KP_Right", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + KP_Home", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + KP_Up", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + KP_Page_Up", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + KP_Insert", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + CTRL + left", function() local w = hl.get_active_workspace(); if not w then return end; hl.dispatch(hl.dsp.workspace.move({ workspace = w.id, monitor = "l" })) end)
hl.bind(mainMod .. " + CTRL + right", function() local w = hl.get_active_workspace(); if not w then return end; hl.dispatch(hl.dsp.workspace.move({ workspace = w.id, monitor = "r" })) end)

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("~/.config/hypr/toggle_scratchpad.sh"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.window_rule({
    name = "suppress-maximize-events",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "float-satty",
    match = {
        class = "^com\\.gabm\\.satty$",
    },
    float = true,
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 2,
        -- https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,
        -- Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false,
        layout = "dwindle",
    },
    -- https://wiki.hyprland.org/Configuring/Variables/#decoration
    decoration = {
        rounding = 10,
        rounding_power = 2,
        -- Change transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        -- https://wiki.hyprland.org/Configuring/Variables/#blur
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
    -- https://wiki.hyprland.org/Configuring/Variables/#animations
    animations = {
        enabled = true,
        -- Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
    },
    -- Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/
    -- "Smart gaps" / "No gaps when only"
    -- uncomment all if you wish to use that.
    -- workspace = w[tv1], gapsout:0, gapsin:0
    -- workspace = f[1], gapsout:0, gapsin:0
    -- windowrule = bordersize 0, floating:0, onworkspace:w[tv1]
    -- windowrule = rounding 0, floating:0, onworkspace:w[tv1]
    -- windowrule = bordersize 0, floating:0, onworkspace:f[1]
    -- windowrule = rounding 0, floating:0, onworkspace:f[1]
    -- See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
    dwindle = {
        preserve_split = true, -- You probably want this
    },
    -- See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
    master = {
        new_status = "master",
    },
    -- https://wiki.hyprland.org/Configuring/Variables/#misc
    misc = {
        force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
        -- vrr = 1 # variable refresh rate for adaptive sync -off because makes screen flicker
        --below settings dont seem to work to wake screen from sleep - using dpms-off instead
        --bootmouse_move_enables_dpms = true
        --key_press_enables_dpms = true
    },
    --############
    --## INPUT ###
    --############
    -- https://wiki.hyprland.org/Configuring/Variables/#input
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "pc104",
        kb_options = "",
        kb_rules = "",
        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
        touchpad = {
            natural_scroll = true,
        },
    },
    -- Example per-device config
    -- See https://wiki.hyprland.org/Configuring/Keywords/#per-device-input-configs for more
    -- https://wiki.hyprland.org/Configuring/Variables/#gestures
    -- gesture = 3, vertical, special, magic
    --##################
    --## KEYBINDINGS ###
    --##################
    -- See https://wiki.hyprland.org/Configuring/Keywords/
    -- Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
    -- Lock screen
    -- Power off monitors
    -- Power on monitors
    -- Screenshot with satty (annotate, Enter copies, Ctrl+S saves)
    -- Toggle screen recording
    -- Random wallpaper
    -- Move focus with mainMod + arrow keys
    -- Switch workspaces with mainMod + [0-9]
    -- Switch workspaces with mainMod + numpad
    -- Switch workspaces with mainMod + numpad (Num Lock off)
    -- Move active window to a workspace with mainMod + SHIFT + [0-9]
    -- Move active window to a workspace with mainMod + SHIFT + numpad
    -- Move active window to a workspace with mainMod + SHIFT + numpad (Num Lock off)
    -- Move windows with mainMod + SHIFT + arrow keys
    -- Move current workspace to left/right monitor
    -- Example special workspace (scratchpad)
    -- Scroll through existing workspaces with mainMod + scroll
    -- Move/resize windows with mainMod + LMB/RMB and dragging
    -- Laptop multimedia keys for volume and LCD brightness
    -- Requires playerctl
    --#############################
    --## WINDOWS AND WORKSPACES ###
    --#############################
    -- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
    -- See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules
    -- Example windowrule
    -- windowrule = float,class:^(kitty)$,title:^(kitty)$
    -- Ignore maximize requests from apps. You'll probably like this.
    -- Open satty (screenshot annotation) floating
    -- Fix some dragging issues with XWayland
})

hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("mako")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("~/.config/hypr/random-wallpaper.sh")
    hl.exec_cmd("pkill waybar; sleep 0.1; waybar")
end)

hl.on("config.reloaded", function()
    hl.exec_cmd("pkill waybar; sleep 0.1; waybar")
end)
