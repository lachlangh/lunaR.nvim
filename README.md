# `lunaR.nvim`

> ⚠️ **Note:** This project is in active development and is not yet stable. Expect rapid changes and breaking updates.
> Use with caution, and feel free to contribute!

### Features (planned so far)
- [ ] Start/stop `R` terminal buffers; attach to `R` script buffers.
- [ ] Execute `R` code chunks in terminal buffers
- [ ] Supplement LSP completions with `R` process state info (global environment objects, `data.frame` names, etc.) 

## Terminal-First Philosophy
`lunaR.nvim` aims to provide a lightweight, alternative approach to R integration with Neovim, delivering a modular, extensible, and *terminal-first* tool tailored to simplicity and efficiency. 
Designed for developers who prioritize customization and streamlined workflows, `lunaR.nvim` complements Neovim’s philosophy by offering robust features without unnecessary overhead.

## Goals of this Project
### Establish a Robust and Efficient Communication Mechanism
Reliable communication between a Neovim buffer and a running R process is critical for seamless functionality. 
This ensures users can send and receive data effortlessly, supporting tasks like code execution, inspection, and result retrieval without interruption.
The core functionality of the plugin will be comprehensively tested to ensure this reliability.

### Define a Well-Documented, Consistent External API
By exposing a clear and consistent API, `lunaR.nvim` encourages extensibility and integration with other tools. 
This enables developers to create plugins and extensions that enhance or complement `lunaR.nvim`’s core functionality. 
For example, by writing extensions targeting developer patterns on Rmd, Quarto, or Sweave projects.

### Develop an R Package with a Query-Response Server
This R package will provide a server, served via HTTP, to respond to queries about the R process state. 
The query-response protocol is caller agnostic, making it equally applicable for Neovim, VS Code, or other environments.

### Complement LSP
The existing language server protocol implementation for R already handles much of the heavy lifting for features like autocompletion and diagnostics; this plugin aims to complement this existing functionality.

### Support modern R Usage
This plugin aligns with modern software standards, targeting recent R versions and assuming a technically proficient audience. 
`lunaR.nvim` will ensure minimal interference with the R environment, making only the necessary changes to establish a connection. 
Any startup or environment changes will be visible to the user, and any changes to R behavior will be strictly opt-in, avoiding interference with global configurations.

## Non-Goals of this Project
### Recreate an RStudio-Like IDE Experience
`lunaR.nvim` is designed to complement a terminal-first workflow rather than replicate the comprehensive features of an IDE like RStudio. 
Unlike RStudio, it does not manage environment configurations or system-level dependencies, assuming users are proficient in setting up their own development environments, supported by appropriate documentation and advice. 
This focus ensures the plugin remains lightweight and aligned with Neovim’s philosophy.

### Fully Implement R-Adjacent Workflows
The plugin won’t aim to handle all functionality for R-adjacent areas like Sweave, RMarkdown, or Quarto. These workflows are better supported by dedicated tools, and handling them fully would detract from `lunaR.nvim`’s core purpose.

