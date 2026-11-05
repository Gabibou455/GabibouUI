# Notifications and commands

These examples use the `window` and `tab` from [Getting started](demarrer.md).

## Show a message

```lua
window:Notify({
    Title = "Saved", Content = "Your settings have been applied.",
    Kind = "success", Duration = 4,
})
```

Kinds: `info`, `success`, `warning`, `error`. Duration is in seconds. The returned notification has `Dismiss()` and `Destroy()`.

## Ask for confirmation

```lua
tab:Button("Reset", function()
    window:Confirm({
        Title = "Reset volume?", Content = "Volume will return to 50.",
        ConfirmText = "Reset",
        Callback = function()
            local volume = window:Get("volume")
            if volume then volume:Set(50, true) end
        end,
    })
end)
```

The callback runs only after confirmation. Cancel does not run it. `Confirm` returns `false` if another confirmation is open.

## Register a searchable command

```lua
window:Command({
    Id = "show_status", Title = "Show status", Keywords = {"status", "info"}, Icon = "info",
    Callback = function()
        window:Notify({Title = "Interface ready", Kind = "success"})
    end,
})
tab:Button("Open commands", function()
    window:OpenCommands()
end)
```

Keep the visible button for touch users. On desktop, `Ctrl+K` attempts to open the palette; your environment may intercept it. Use arrows and Enter, mouse or touch to activate results. `CloseCommands()` closes the palette; `RemoveCommand("show_status")` removes a command.

## Offer a Discord link

`window:PromptDiscord(urlOrOptions)` opens an invite dialog using your supplied URL. Alternatively, pass `DiscordPrompt` when creating the window. It is disabled by default and never joins a server automatically. Use a real invitation for your project.
