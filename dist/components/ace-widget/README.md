[![Published on webcomponents.org](https://img.shields.io/badge/webcomponents.org-published-blue.svg)](https://www.webcomponents.org/element/LostInBrittany/ace-widget)

# ace-widget #

> Even <strong>more</strong> embeddable code editor
> Custom Element - just one tag, and no JS needed to provide
> [Ace](http://ace.c9.io/) - The High Performance Code Editor
>
> Based on [pjako's fork](https://github.com/pjako/ace-element)
> of [PolymerLabs ace-element](https://github.com/PolymerLabs/ace-element).
>
> Hybrid Polymer element, 1.x-2.x ready


## Doc and demo

https://lostinbrittany.github.io/ace-widget/


## Usage example

<!---
```
<custom-element-demo>
  <template>
    <script src="../webcomponentsjs/webcomponents-lite.js"></script>
    <link rel="import" href="ace-widget.html">
    <next-code-block></next-code-block>
  </template>
</custom-element-demo>
```
-->
```html
  <ace-widget placeholder="Write something... Anything..." initial-focus>
  </ace-widget>
```


## Install

Install the component using [Bower](http://bower.io/):

```sh
$ bower install LostInBrittany/ace-widget --save
```

Or [download as ZIP](https://github.com/LostInBrittany/ace-widget/archive/gh-pages.zip).


## Usage

1. Import Web Components' polyfill (if needed):

    ```html
    <script src="bower_components/webcomponentsjs/webcomponents.min.js"></script>
    ```

2. Import Custom Element:

    ```html
    <link rel="import" href="bower_components/ace-widget/ace-widget.html">
    ```

3. Start using it!

    ```html
    <ace-widget>Editable code here</ace-widget>
    ```

### Note on ShadowDOM

The new tools from the Polymer team, like [Polymer CLI](https://github.com/Polymer/polymer-cli) use the true *shadow-dom* instead of *shady-dom*, by means of the setup of Polymer options:

```
    // setup Polymer options
    window.Polymer = {lazyRegister: true, dom: 'shadow'};
```

Ace editor isn't currently not compatible with ShadowDOM, as it creates global styles that doesn't pass the ShadowDOM border.
In order to make **ace-widget** work, I've taken inspiration from the [ace-shim-about-shadow-dom project](https://github.com/valaxy/ace-shim-about-shadow-dom/) and made a Polymer behavior that detects if an application using **ace-widget** is in ShadowDOM mode, and if it is, it copies Ace editor's styles into the component ShadowDOM.


## Attributes

Attribute     | Type      | Default | Description
---           | ---       | ---     | ---
`theme`       | *String*  | ``      | `Editor#setTheme` at [Ace API](http://ace.c9.io/#nav=api&api=editor)
`mode`        | *String*  | ``      | `EditSession#setMode` at [Ace API](http://ace.c9.io/#nav=api&api=edit_session)
`font-size`   | *String*  | ``      | `Editor#setFontSize` at [Ace API](http://ace.c9.io/#nav=api&api=editor)
`softtabs`    | *Boolean* | ``      | `EditSession#setUseSoftTabs()` at [Ace API](http://ace.c9.io/#nav=api&api=edit_session)
`tab-size`    | *Boolean* | ``      | `Session#setTabSize()` at [Ace API](http://ace.c9.io/#nav=api&api=edit_session)
`readonly`    | *Boolean* | ``      | `Editor#setReadOnly()` at [Ace API](http://ace.c9.io/#nav=api&api=editor)
`wrap`        | *Boolean* | ``      | `Session#setWrapMode()` at [Ace API](http://ace.c9.io/#nav=api&api=edit_session)
`autoComplete` | *Object* | ``   | Callback for `langTools.addCompleter` like the example at [Ace API](https://github.com/ajaxorg/ace/wiki/How-to-enable-Autocomplete-in-the-Ace-editor)
`minlines`    | *Number*  | 15      | `Editor.setOptions({minlines: minlines})`
`maxlines`    | *Number*  | 30      | `Editor.setOptions({minlines: maxlines})`
`initialFocus`| *Boolean* | ``      | If true, `Editor.focus()` is called upon initialisation
`placeholder` | *String*  | ``      | A placeholder text to show when the editor is empty

## Properties

Name        |  Description
---         | ---
`editor`    | Ace [editor](http://ace.c9.io/#nav=api&api=editor) object.
`value`     | [editor.get-/setValue()](http://ace.c9.io/#nav=api&api=editor)

## Events

Name             |  Description
---              | ---
`editor-content` | Triggered when editor content gets changed
`editor-ready`   | Triggered once Ace editor instance is created.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## License

[MIT License](http://opensource.org/licenses/MIT)
