{ toTOML
, writeText
}:

name: contents: writeText name ((toTOML contents) + "\n")
