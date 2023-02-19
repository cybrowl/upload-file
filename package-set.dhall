let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.2-20230217/package-set.dhall sha256:0a6f87bdacb4032f4b273d936225735ca4a0b0378de1f81e4bc4c6b4c5bad8a5
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides
