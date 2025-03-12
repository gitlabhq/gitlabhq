class Logger {
  isQuiet: boolean

  constructor(isQuiet: boolean) {
    this.isQuiet = isQuiet
  }

  log(...args: string[]) {
    this.isQuiet ? null : console.log(...args)
  }

  error(...args: string[]) {
    this.isQuiet ? null : console.error(...args)
  }

  colorize(color: string, text: string) {
    var prefix = colors[color]
    if (!prefix) {
      throw new Error("No color named: " + color)
    }
    return prefix + text + colors.reset
  }

  // Shortcuts to `.colorize`, add more as-needed.

  red(text: string) {
    return this.colorize("red", text)
  }

  green(text: string) {
    return this.colorize("green", text)
  }

  bright(text: string) {
    return this.colorize("bright", text)
  }
}


const colors: {[key: string]: string} = {
  yellow:   "\x1b[33m",
  red:      "\x1b[31m",
  green:    "\x1b[32m",
  blue:     "\x1b[34m",
  magenta:  "\x1b[35m",
  cyan:     "\x1b[36m",
  reset:    "\x1b[0m",
  bright:   "\x1b[1m",
  dim:      "\x1b[2m",
}

export default Logger
