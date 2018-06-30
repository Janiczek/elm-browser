# elm-browser

Elm project browser and editor inspired by Smalltalk's System Browser.

<img alt="App Screenshot" src="https://github.com/Janiczek/elm-browser/raw/master/resources/readme/app.png" width="640">

## Usage

```
yarn && yarn build && yarn start
```

## TODO

- [ ] There can be multiple modules with the same name - differentiate the IDs by the package author/name, and show a hint in the case of duplicity
- [ ] incremental indexing
- [ ] compilation optional?
- [ ] secondary highlight for packages: highlight those packages that depend on the currently selected one
- [ ] secondary highlight for modules: highlight the package it's originating from
- [ ] fourth column - groups based on the documentation?
