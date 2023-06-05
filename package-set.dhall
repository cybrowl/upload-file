let upstream = https://github.com/internet-computer/base-package-set/releases/download/moc-0.8.6/package-set.dhall sha256:4a7734568f1c7e5dfe91d2ba802c9b6f218d7836904dea5a999a3096f6ef0d3c
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { 
    name = "base",
    repo = "https://github.com/dfinity/motoko-base",
    version = "5d225a427fb785aacb3051acab4be69651c19101", 
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