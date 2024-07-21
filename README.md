# NavBuf

NavBuf is a Neovim plugin designed to improve file navigation by leveraging the built-in MARK
feature. 

![navbuf](https://github.com/davidbujok/navbuf/assets/119963544/36a497e0-8b34-4411-a841-30c83c00520e)

https://github.com/user-attachments/assets/b1a635cb-3354-46a1-a1d4-7ad6e0c04185


## Features

- **Popup Window Navigation:** Invoke a popup window with a user-defined keybind to list marks.
Navigate to a desired mark by pressing a single letter.
- **Case Translation:** All Neovim capital marks are translated to lower case, eliminating the need
to press Shift + letter.
- **Buffer Mark Navigation:** Press the period key to switch to a buffer's lower-case mark when the
plugin is invoked.
- **Quick Navigation:** An optional keybind allows moving to a file marked with a capital MARK and
then immediately picking up the buffer's mark related to that file without pressing the period key.
This enables quick navigation with just three key presses.
- **Instant Mark List:** Provides an instant list of defined mappings, aiding users who are unsure
or forget the mappings set for a given buffer.


### Installation

* By deafult the plugin reports back all your A-Z mappings, you can limit that with extra
  configuration 

```
    {
        'davidbujok/navbuf',
        config = function()
            require('navbuf').setup()
        end
    },
```

### Optional config

* marks is just a list of capital letters that you want to see in the popup window.
  - It's best to setup this to a short list of capital marks that you use dynamically. 
  - E.g in my setup the V is reserved for init.lua/.vimrc and I don't need
    the reminder of that in the popup window. 
  - Less marks will make the list more readable and faster to navigate.
```
    {
        'davidbujok/navbuf',
        config = function()
            require('navbuf').setup({
                marks = {"A", "B", "C", "D"},
            })
        end
    },
```

### Setup your own keymaps

* Setup your own mapping

```
vim.keymap.set("n", "'", "<CMD>lua Navbuf()<CR>", { desc = "marks" })
```

* Go to marked file and immediately pick buffer's mark

```
vim.keymap.set("n", "'", "<CMD>lua NavbufTwoStep()", { desc = "marks" })
```
