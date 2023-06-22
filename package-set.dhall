let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.9.3-20230619/package-set.dhall

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { 
    name = "base",
    repo = "https://github.com/dfinity/motoko-base",
    version = "9461c3adc0c6d216f3d7670518a92ad91d348442", 
    dependencies = [] : List Text
  },
  { 
    name = "hashmap",
    repo = "https://github.com/ZhenyaUsenko/motoko-hash-map",
    version = "master", 
    dependencies = [] : List Text
  },
] : List Package

in  upstream # additions