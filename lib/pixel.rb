class Pixel
  def self.size
    15
  end

  FOREGROUND = {
    default:       "39",
    black:         "30",
    red:           "31",
    green:         "32",
    yellow:        "33",
    blue:          "34",
    magenta:       "35",
    cyan:          "36",
    light_gray:    "37",
    dark_gray:     "90",
    light_red:     "91",
    light_green:   "92",
    light_yellow:  "93",
    light_blue:    "94",
    light_magenta: "95",
    light_cyan:    "96",
    white:         "97",
  }

  BACKGROUND = {
    default:       "49",
    black:         "40",
    red:           "41",
    green:         "42",
    yellow:        "43",
    blue:          "44",
    magenta:       "45",
    cyan:          "46",
    light_gray:    "47",
    dark_gray:     "100",
    light_red:     "101",
    light_green:   "102",
    light_yellow:  "103",
    light_blue:    "104",
    light_magenta: "105",
    light_cyan:    "106",
    white:         "107",
  }

  STYLES = {
    default: "1",
    bold: "1"
  }

  def self.create(
    char: ' ',
    background: :default,
    foreground: :default,
    style: :default
  )
    "\e[#{STYLES[style]};" \
      "#{FOREGROUND[foreground]};" \
      "#{BACKGROUND[background]}" \
      "m#{char[0]}\e[0m"
  end
end
