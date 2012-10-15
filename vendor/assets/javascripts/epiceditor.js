/**
 * EpicEditor - An Embeddable JavaScript Markdown Editor (https://github.com/OscarGodson/EpicEditor)
 * Copyright (c) 2011-2012, Oscar Godson. (MIT Licensed)
 */

(function (window, undefined) {
  /**
   * Applies attributes to a DOM object
   * @param  {object} context The DOM obj you want to apply the attributes to
   * @param  {object} attrs A key/value pair of attributes you want to apply
   * @returns {undefined}
   */
  function _applyAttrs(context, attrs) {
    for (var attr in attrs) {
      if (attrs.hasOwnProperty(attr)) {
        context[attr] = attrs[attr];
      }
    }
  }

  /**
   * Applies styles to a DOM object
   * @param  {object} context The DOM obj you want to apply the attributes to
   * @param  {object} attrs A key/value pair of attributes you want to apply
   * @returns {undefined}
   */
  function _applyStyles(context, attrs) {
    for (var attr in attrs) {
      if (attrs.hasOwnProperty(attr)) {
        context.style[attr] = attrs[attr];
      }
    }
  }

  /**
   * Returns a DOM objects computed style
   * @param  {object} el The element you want to get the style from
   * @param  {string} styleProp The property you want to get from the element
   * @returns {string} Returns a string of the value. If property is not set it will return a blank string
   */
  function _getStyle(el, styleProp) {
    var x = el
      , y = null;
    if (window.getComputedStyle) {
      y = document.defaultView.getComputedStyle(x, null).getPropertyValue(styleProp);
    }
    else if (x.currentStyle) {
      y = x.currentStyle[styleProp];
    }
    return y;
  }

  /**
   * Saves the current style state for the styles requested, then applys styles
   * to overwrite the existing one. The old styles are returned as an object so
   * you can pass it back in when you want to revert back to the old style
   * @param   {object} el     The element to get the styles of
   * @param   {string} type   Can be "save" or "apply". apply will just apply styles you give it. Save will write styles
   * @param   {object} styles Key/value style/property pairs
   * @returns {object}
   */
  function _saveStyleState(el, type, styles) {
    var returnState = {}
      , style;
    if (type === 'save') {
      for (style in styles) {
        if (styles.hasOwnProperty(style)) {
          returnState[style] = _getStyle(el, style);
        }
      }
      // After it's all done saving all the previous states, change the styles
      _applyStyles(el, styles);
    }
    else if (type === 'apply') {
      _applyStyles(el, styles);
    }
    return returnState;
  }

  /**
   * Gets an elements total width including it's borders and padding
   * @param  {object} el The element to get the total width of
   * @returns {int}
   */
  function _outerWidth(el) {
    var b = parseInt(_getStyle(el, 'border-left-width'), 10) + parseInt(_getStyle(el, 'border-right-width'), 10)
      , p = parseInt(_getStyle(el, 'padding-left'), 10) + parseInt(_getStyle(el, 'padding-right'), 10)
      , w = el.offsetWidth
      , t;
    // For IE in case no border is set and it defaults to "medium"
    if (isNaN(b)) { b = 0; }
    t = b + p + w;
    return t;
  }

  /**
   * Gets an elements total height including it's borders and padding
   * @param  {object} el The element to get the total width of
   * @returns {int}
   */
  function _outerHeight(el) {
    var b = parseInt(_getStyle(el, 'border-top-width'), 10) + parseInt(_getStyle(el, 'border-bottom-width'), 10)
      , p = parseInt(_getStyle(el, 'padding-top'), 10) + parseInt(_getStyle(el, 'padding-bottom'), 10)
      , w = el.offsetHeight
      , t;
    // For IE in case no border is set and it defaults to "medium"
    if (isNaN(b)) { b = 0; }
    t = b + p + w;
    return t;
  }

  /**
   * Inserts a <link> tag specifically for CSS
   * @param  {string} path The path to the CSS file
   * @param  {object} context In what context you want to apply this to (document, iframe, etc)
   * @param  {string} id An id for you to reference later for changing properties of the <link>
   * @returns {undefined}
   */
  function _insertCSSLink(path, context, id) {
    id = id || '';
    var headID = context.getElementsByTagName("head")[0]
      , cssNode = context.createElement('link');
    
    _applyAttrs(cssNode, {
      type: 'text/css'
    , id: id
    , rel: 'stylesheet'
    , href: path
    , name: path
    , media: 'screen'
    });

    headID.appendChild(cssNode);
  }

  // Simply replaces a class (o), to a new class (n) on an element provided (e)
  function _replaceClass(e, o, n) {
    e.className = e.className.replace(o, n);
  }

  // Feature detects an iframe to get the inner document for writing to
  function _getIframeInnards(el) {
    return el.contentDocument || el.contentWindow.document;
  }

  // Grabs the text from an element and preserves whitespace
  function _getText(el) {
    var theText;
    if (document.body.innerText) {
      theText = el.innerText;
    }
    else {
      // First replace <br>s before replacing the rest of the HTML
      theText = el.innerHTML.replace(/<br>/gi, "\n");
      // Now we can clean the HTML
      theText = theText.replace(/<(?:.|\n)*?>/gm, '');
      // Now fix HTML entities
      theText = theText.replace(/&lt;/gi, '<');
      theText = theText.replace(/&gt;/gi, '>');
    }
    return theText;
  }

  function _setText(el, content) {
    if (document.body.innerText) {
      el.innerText = content;
    }
    else {
      // Don't convert lt/gt characters as HTML when viewing the editor window
      // TODO: Write a test to catch regressions for this
      content = content.replace(/</g, '&lt;');
      content = content.replace(/>/g, '&gt;');
      content = content.replace(/\n/g, '<br>');
      el.innerHTML = content;
    }
    return true;
  }

  /**
   * Will return the version number if the browser is IE. If not will return -1
   * TRY NEVER TO USE THIS AND USE FEATURE DETECTION IF POSSIBLE
   * @returns {Number} -1 if false or the version number if true
   */
  function _isIE() {
    var rv = -1 // Return value assumes failure.
      , ua = navigator.userAgent
      , re;
    if (navigator.appName == 'Microsoft Internet Explorer') {
      re = /MSIE ([0-9]{1,}[\.0-9]{0,})/;
      if (re.exec(ua) != null) {
        rv = parseFloat(RegExp.$1, 10);
      }
    }
    return rv;
  }

  /**
   * Determines if supplied value is a function
   * @param {object} object to determine type
   */
  function _isFunction(functionToCheck) {
    var getType = {};
    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
  }

  /**
   * Overwrites obj1's values with obj2's and adds obj2's if non existent in obj1
   * @param {boolean} [deepMerge=false] If true, will deep merge meaning it will merge sub-objects like {obj:obj2{foo:'bar'}}
   * @param {object} first object
   * @param {object} second object
   * @returnss {object} a new object based on obj1 and obj2
   */
  function _mergeObjs() {
    // copy reference to target object
    var target = arguments[0] || {}
      , i = 1
      , length = arguments.length
      , deep = false
      , options
      , name
      , src
      , copy

    // Handle a deep copy situation
    if (typeof target === "boolean") {
      deep = target;
      target = arguments[1] || {};
      // skip the boolean and the target
      i = 2;
    }

    // Handle case when target is a string or something (possible in deep copy)
    if (typeof target !== "object" && !_isFunction(target)) {
      target = {};
    }
    // extend jQuery itself if only one argument is passed
    if (length === i) {
      target = this;
      --i;
    }

    for (; i < length; i++) {
      // Only deal with non-null/undefined values
      if ((options = arguments[i]) != null) {
        // Extend the base object
        for (name in options) {
          // @NOTE: added hasOwnProperty check
          if (options.hasOwnProperty(name)) {
            src = target[name];
            copy = options[name];
            // Prevent never-ending loop
            if (target === copy) {
              continue;
            }
            // Recurse if we're merging object values
            if (deep && copy && typeof copy === "object" && !copy.nodeType) {
              target[name] = _mergeObjs(deep,
                // Never move original objects, clone them
                src || (copy.length != null ? [] : {})
                , copy);
            } else if (copy !== undefined) { // Don't bring in undefined values
              target[name] = copy;
            }
          }
        }
      }
    }

    // Return the modified object
    return target;
  }

  /**
   * Initiates the EpicEditor object and sets up offline storage as well
   * @class Represents an EpicEditor instance
   * @param {object} options An optional customization object
   * @returns {object} EpicEditor will be returned
   */
  function EpicEditor(options) {
    // Default settings will be overwritten/extended by options arg
    var self = this
      , opts = options || {}
      , _defaultFileSchema
      , _defaultFile
      , defaults = { container: 'epiceditor'
        , basePath: 'epiceditor'
        , clientSideStorage: true
        , localStorageName: 'epiceditor'
        , file: { name: null
        , defaultContent: ''
          , autoSave: 100 // Set to false for no auto saving
          }
        , theme: { base: '/themes/base/epiceditor.css'
          , preview: '/themes/preview/github.css'
          , editor: '/themes/editor/epic-dark.css'
          }
        , focusOnLoad: false
        , shortcut: { modifier: 18 // alt keycode
          , fullscreen: 70 // f keycode
          , preview: 80 // p keycode
          , edit: 79 // o keycode
          }
        , parser: typeof marked == 'function' ? marked : null
        }
      , defaultStorage;

    self.settings = _mergeObjs(true, defaults, opts);

    if (!(typeof self.settings.parser == 'function' && typeof self.settings.parser('TEST') == 'string')) {
      self.settings.parser = function (str) {
        return str;
      }
    }


    // Grab the container element and save it to self.element
    // if it's a string assume it's an ID and if it's an object
    // assume it's a DOM element
    if (typeof self.settings.container == 'string') {
      self.element = document.getElementById(self.settings.container);
    }
    else if (typeof self.settings.container == 'object') {
      self.element = self.settings.container;
    }
    
    // Figure out the file name. If no file name is given we'll use the ID.
    // If there's no ID either we'll use a namespaced file name that's incremented
    // based on the calling order. As long as it doesn't change, drafts will be saved.
    if (!self.settings.file.name) {
      if (typeof self.settings.container == 'string') {
        self.settings.file.name = self.settings.container;
      }
      else if (typeof self.settings.container == 'object') {
        if (self.element.id) {
          self.settings.file.name = self.element.id;
        }
        else {
          if (!EpicEditor._data.unnamedEditors) {
            EpicEditor._data.unnamedEditors = [];
          }
          EpicEditor._data.unnamedEditors.push(self);
          self.settings.file.name = '__epiceditor-untitled-' + EpicEditor._data.unnamedEditors.length;
        }
      }
    }

    // Protect the id and overwrite if passed in as an option
    // TODO: Put underscrore to denote that this is private
    self._instanceId = 'epiceditor-' + Math.round(Math.random() * 100000);
    self._storage = {};
    self._canSave = true;

    // Setup local storage of files
    self._defaultFileSchema = function () {
      return {
        content: self.settings.file.defaultContent
      , created: new Date()
      , modified: new Date()
      }
    }

    if (localStorage && self.settings.clientSideStorage) {
      this._storage = localStorage;
      if (this._storage[self.settings.localStorageName] && self.getFiles(self.settings.file.name) === undefined) {
        _defaultFile = self.getFiles(self.settings.file.name);
        _defaultFile = self._defaultFileSchema();
        _defaultFile.content = self.settings.file.defaultContent;
      }
    }

    if (!this._storage[self.settings.localStorageName]) {
      defaultStorage = {};
      defaultStorage[self.settings.file.name] = self._defaultFileSchema();
      defaultStorage = JSON.stringify(defaultStorage);
      this._storage[self.settings.localStorageName] = defaultStorage;
    }

    // Now that it exists, allow binding of events if it doesn't exist yet
    if (!self.events) {
      self.events = {};
    }

    return this;
  }

  /**
   * Inserts the EpicEditor into the DOM via an iframe and gets it ready for editing and previewing
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.load = function (callback) {
    // TODO: Gotta get the privates with underscores!
    // TODO: Gotta document what these are for...
    var self = this
      , _HtmlTemplates
      , iframeElement
      , baseTag
      , widthDiff
      , heightDiff
      , utilBtns
      , utilBar
      , utilBarTimer
      , keypressTimer
      , mousePos = { y: -1, x: -1 }
      , _elementStates
      , _isInEdit
      , nativeFs = document.body.webkitRequestFullScreen ? true : false
      , _goFullscreen
      , _exitFullscreen
      , elementsToResize
      , fsElement
      , isMod = false
      , isCtrl = false
      , eventableIframes
      , i; // i is reused for loops

    callback = callback || function () {};

    // This needs to replace the use of classes to check the state of EE
    self.eeState = {
      fullscreen: false
    , preview: false
    , edit: true
    , loaded: false
    , unloaded: false
    }

    // The editor HTML
    // TODO: edit-mode class should be dynamically added
    _HtmlTemplates = {
      // This is wrapping iframe element. It contains the other two iframes and the utilbar
      chrome:   '<div id="epiceditor-wrapper" class="epiceditor-edit-mode">' +
                  '<iframe frameborder="0" id="epiceditor-editor-frame"></iframe>' +
                  '<iframe frameborder="0" id="epiceditor-previewer-frame"></iframe>' +
                  '<div id="epiceditor-utilbar">' +
                    '<img width="30" src="' + this.settings.basePath + '/images/preview.png" title="Toggle Preview Mode" class="epiceditor-toggle-btn epiceditor-toggle-preview-btn"> ' +
                    '<img width="30" src="' + this.settings.basePath + '/images/edit.png" title="Toggle Edit Mode" class="epiceditor-toggle-btn epiceditor-toggle-edit-btn"> ' +
                    '<img width="30" src="' + this.settings.basePath + '/images/fullscreen.png" title="Enter Fullscreen" class="epiceditor-fullscreen-btn">' +
                  '</div>' +
                '</div>'
    
    // The previewer is just an empty box for the generated HTML to go into
    , previewer: '<div id="epiceditor-preview"></div>'
    };

    // Used to setup the initial size of the iframes
    function setupIframeStyles(el) {
      for (var x = 0; x < el.length; x++) {
        el[x].style.width  = self.element.offsetWidth - widthDiff + 'px';
        el[x].style.height = self.element.offsetHeight - heightDiff + 'px';
      }
    }

    // Used for resetting the width of EE mainly for fluid width containers
    function resetWidth(el) {
      widthDiff = _outerWidth(self.element) - self.element.offsetWidth;
      for (var x = 0; x < el.length; x++) {
        el[x].style.width  = self.element.offsetWidth - widthDiff + 'px';
      }
    }
    // Write an iframe and then select it for the editor
    self.element.innerHTML = '<iframe scrolling="no" frameborder="0" id= "' + self._instanceId + '"></iframe>';
    iframeElement = document.getElementById(self._instanceId);
    
    // Store a reference to the iframeElement itself
    self.iframeElement = iframeElement;

    // Grab the innards of the iframe (returns the document.body)
    // TODO: Change self.iframe to self.iframeDocument
    self.iframe = _getIframeInnards(iframeElement);
    self.iframe.open();
    self.iframe.write(_HtmlTemplates.chrome);

    // Now that we got the innards of the iframe, we can grab the other iframes
    self.editorIframe = self.iframe.getElementById('epiceditor-editor-frame')
    self.previewerIframe = self.iframe.getElementById('epiceditor-previewer-frame');

    // Setup the editor iframe
    self.editorIframeDocument = _getIframeInnards(self.editorIframe);
    self.editorIframeDocument.open();
    // Need something for... you guessed it, Firefox
    self.editorIframeDocument.write('');
    self.editorIframeDocument.close();
    
    // Setup the previewer iframe
    self.previewerIframeDocument = _getIframeInnards(self.previewerIframe);
    self.previewerIframeDocument.open();
    self.previewerIframeDocument.write(_HtmlTemplates.previewer);

    // Base tag is added so that links will open a new tab and not inside of the iframes
    baseTag = self.previewerIframeDocument.createElement('base');
    baseTag.target = '_blank';
    self.previewerIframeDocument.getElementsByTagName('head')[0].appendChild(baseTag);

    self.previewerIframeDocument.close();

    // Set the default styles for the iframe
    widthDiff = _outerWidth(self.element) - self.element.offsetWidth;
    heightDiff = _outerHeight(self.element) - self.element.offsetHeight;
    elementsToResize = [self.iframeElement, self.editorIframe, self.previewerIframe];
     
    setupIframeStyles(elementsToResize);

    // Insert Base Stylesheet
    _insertCSSLink(self.settings.basePath + self.settings.theme.base, self.iframe, 'theme');
    
    // Insert Editor Stylesheet
    _insertCSSLink(self.settings.basePath + self.settings.theme.editor, self.editorIframeDocument, 'theme');
    
    // Insert Previewer Stylesheet
    _insertCSSLink(self.settings.basePath + self.settings.theme.preview, self.previewerIframeDocument, 'theme');

    // Add a relative style to the overall wrapper to keep CSS relative to the editor
    self.iframe.getElementById('epiceditor-wrapper').style.position = 'relative';

    // Now grab the editor and previewer for later use
    self.editor = self.editorIframeDocument.body;
    self.previewer = self.previewerIframeDocument.getElementById('epiceditor-preview');
   
    self.editor.contentEditable = true;
 
    // Firefox's <body> gets all fucked up so, to be sure, we need to hardcode it
    self.iframe.body.style.height = this.element.offsetHeight + 'px';

    // Should actually check what mode it's in!
    this.previewerIframe.style.display = 'none';

    // FIXME figure out why it needs +2 px
    if (_isIE() > -1) {
      this.previewer.style.height = parseInt(_getStyle(this.previewer, 'height'), 10) + 2;
    }

    // If there is a file to be opened with that filename and it has content...
    this.open(self.settings.file.name);

    if (self.settings.focusOnLoad) {
      // We need to wait until all three iframes are done loading by waiting until the parent
      // iframe's ready state == complete, then we can focus on the contenteditable
      self.iframe.addEventListener('readystatechange', function () {
        if (self.iframe.readyState == 'complete') {
          self.editorIframeDocument.body.focus();
        }
      });
    }

    // TODO: Should probably have an ID since we only select one
    // TODO: Should probably have an underscore?
    utilBtns = self.iframe.getElementById('epiceditor-utilbar');

    _elementStates = {}
    _goFullscreen = function (el) {
      
      if (self.eeState.fullscreen) {
        _exitFullscreen(el);
        return;
      }

      if (nativeFs) {
        el.webkitRequestFullScreen();
      }

      _isInEdit = self.eeState.edit;

      // Set the state of EE in fullscreen
      // We set edit and preview to true also because they're visible
      // we might want to allow fullscreen edit mode without preview (like a "zen" mode)
      self.eeState.fullscreen = true;
      self.eeState.edit = true;
      self.eeState.preview = true;

      // Cache calculations
      var windowInnerWidth = window.innerWidth
        , windowInnerHeight = window.innerHeight
        , windowOuterWidth = window.outerWidth
        , windowOuterHeight = window.outerHeight;

      // Without this the scrollbars will get hidden when scrolled to the bottom in faux fullscreen (see #66)
      if (!nativeFs) {
        windowOuterHeight = window.innerHeight;
      }

      // This MUST come first because the editor is 100% width so if we change the width of the iframe or wrapper
      // the editor's width wont be the same as before
      _elementStates.editorIframe = _saveStyleState(self.editorIframe, 'save', {
        'width': windowOuterWidth / 2 + 'px'
      , 'height': windowOuterHeight + 'px'
      , 'float': 'left' // Most browsers
      , 'cssFloat': 'left' // FF
      , 'styleFloat': 'left' // Older IEs
      , 'display': 'block'
      });

      // the previewer
      _elementStates.previewerIframe = _saveStyleState(self.previewerIframe, 'save', {
        'width': windowOuterWidth / 2 + 'px'
      , 'height': windowOuterHeight + 'px'
      , 'float': 'right' // Most browsers
      , 'cssFloat': 'right' // FF
      , 'styleFloat': 'right' // Older IEs
      , 'display': 'block'
      });

      // Setup the containing element CSS for fullscreen
      _elementStates.element = _saveStyleState(self.element, 'save', {
        'position': 'fixed'
      , 'top': '0'
      , 'left': '0'
      , 'width': '100%'
      , 'z-index': '9999' // Most browsers
      , 'zIndex': '9999' // Firefox
      , 'border': 'none'
      , 'margin': '0'
      // Should use the base styles background!
      , 'background': _getStyle(self.editor, 'background-color') // Try to hide the site below
      , 'height': windowInnerHeight + 'px'
      });

      // The iframe element
      _elementStates.iframeElement = _saveStyleState(self.iframeElement, 'save', {
        'width': windowOuterWidth + 'px'
      , 'height': windowInnerHeight + 'px'
      });

      // ...Oh, and hide the buttons and prevent scrolling
      utilBtns.style.visibility = 'hidden';

      if (!nativeFs) {
        document.body.style.overflow = 'hidden';
      }

      self.preview();

      self.editorIframeDocument.body.focus();
    };

    _exitFullscreen = function (el) {
      _saveStyleState(self.element, 'apply', _elementStates.element);
      _saveStyleState(self.iframeElement, 'apply', _elementStates.iframeElement);
      _saveStyleState(self.editorIframe, 'apply', _elementStates.editorIframe);
      _saveStyleState(self.previewerIframe, 'apply', _elementStates.previewerIframe);
     
      // We want to always revert back to the original styles in the CSS so,
      // if it's a fluid width container it will expand on resize and not get
      // stuck at a specific width after closing fullscreen.
      self.element.style.width = '';
      self.element.style.height = '';

      utilBtns.style.visibility = 'visible';
      
      if (!nativeFs) {
        document.body.style.overflow = 'auto';
      }
      else {
        document.webkitCancelFullScreen();
      }
      // Put the editor back in the right state
      // TODO: This is ugly... how do we make this nicer?
      self.eeState.fullscreen = false;
      
      if (_isInEdit) {
        self.edit();
      }
      else {
        self.preview();
      }

      resetWidth(elementsToResize);
    };

    // This setups up live previews by triggering preview() IF in fullscreen on keyup
    self.editor.addEventListener('keyup', function () {
      if (keypressTimer) {
        window.clearTimeout(keypressTimer);
      }
      keypressTimer = window.setTimeout(function () {
        if (self.eeState.fullscreen) {
          self.preview();
        }
      }, 250);
    });
    
    fsElement = self.iframeElement;

    // Sets up the onclick event on utility buttons
    utilBtns.addEventListener('click', function (e) {
      var targetClass = e.target.className;
      if (targetClass.indexOf('epiceditor-toggle-preview-btn') > -1) {
        self.preview();
      }
      else if (targetClass.indexOf('epiceditor-toggle-edit-btn') > -1) {
        self.edit();
      }
      else if (targetClass.indexOf('epiceditor-fullscreen-btn') > -1) {
        _goFullscreen(fsElement);
      }
    });

    // Sets up the NATIVE fullscreen editor/previewer for WebKit
    if (document.body.webkitRequestFullScreen) {
      fsElement.addEventListener('webkitfullscreenchange', function () {
        if (!document.webkitIsFullScreen) {
          _exitFullscreen(fsElement);
        }
      }, false);
    }

    utilBar = self.iframe.getElementById('epiceditor-utilbar');

    // Hide it at first until they move their mouse
    utilBar.style.display = 'none';

    utilBar.addEventListener('mouseover', function () {
      if (utilBarTimer) {
        clearTimeout(utilBarTimer);
      }
    });

    function utilBarHandler(e) {
      // Here we check if the mouse has moves more than 5px in any direction before triggering the mousemove code
      // we do this for 2 reasons:
      // 1. On Mac OS X lion when you scroll and it does the iOS like "jump" when it hits the top/bottom of the page itll fire off
      //    a mousemove of a few pixels depending on how hard you scroll
      // 2. We give a slight buffer to the user in case he barely touches his touchpad or mouse and not trigger the UI
      if (Math.abs(mousePos.y - e.pageY) >= 5 || Math.abs(mousePos.x - e.pageX) >= 5) {
        utilBar.style.display = 'block';
        // if we have a timer already running, kill it out
        if (utilBarTimer) {
          clearTimeout(utilBarTimer);
        }

        // begin a new timer that hides our object after 1000 ms
        utilBarTimer = window.setTimeout(function () {
          utilBar.style.display = 'none';
        }, 1000);
      }
      mousePos = { y: e.pageY, x: e.pageX };
    }
 
    // Add keyboard shortcuts for convenience.
    function shortcutHandler(e) {
      if (e.keyCode == self.settings.shortcut.modifier) { isMod = true } // check for modifier press(default is alt key), save to var
      if (e.keyCode == 17) { isCtrl = true } // check for ctrl/cmnd press, in order to catch ctrl/cmnd + s

      // Check for alt+p and make sure were not in fullscreen - default shortcut to switch to preview
      if (isMod === true && e.keyCode == self.settings.shortcut.preview && !self.eeState.fullscreen) {
        e.preventDefault();
        self.preview();
      }
      // Check for alt+o - default shortcut to switch back to the editor
      if (isMod === true && e.keyCode == self.settings.shortcut.edit) {
        e.preventDefault();
        if (!self.eeState.fullscreen) {
          self.edit();
        }
      }
      // Check for alt+f - default shortcut to make editor fullscreen
      if (isMod === true && e.keyCode == self.settings.shortcut.fullscreen) {
        e.preventDefault();
        _goFullscreen(fsElement);
      }

      // Set the modifier key to false once *any* key combo is completed
      // or else, on Windows, hitting the alt key will lock the isMod state to true (ticket #133)
      if (isMod === true && e.keyCode !== self.settings.shortcut.modifier) {
        isMod = false;
      }

      // When a user presses "esc", revert everything!
      if (e.keyCode == 27 && self.eeState.fullscreen) {
        if (!document.body.webkitRequestFullScreen) {
          _exitFullscreen(fsElement);
        }
      }

      // Check for ctrl + s (since a lot of people do it out of habit) and make it do nothing
      if (isCtrl === true && e.keyCode == 83) {
        self.save();
        e.preventDefault();
        isCtrl = false;
      }

      // Do the same for Mac now (metaKey == cmd).
      if (e.metaKey && e.keyCode == 83) {
        self.save();
        e.preventDefault();
      }

    }
    
    function shortcutUpHandler(e) {
      if (e.keyCode == self.settings.shortcut.modifier) { isMod = false }
      if (e.keyCode == 17) { isCtrl = false }
    }

    // Hide and show the util bar based on mouse movements
    eventableIframes = [self.previewerIframeDocument, self.editorIframeDocument];
    
    for (i = 0; i < eventableIframes.length; i++) {
      eventableIframes[i].addEventListener('mousemove', function (e) {
        utilBarHandler(e);
      });
      eventableIframes[i].addEventListener('scroll', function (e) {
        utilBarHandler(e);
      });
      eventableIframes[i].addEventListener('keyup', function (e) {
        shortcutUpHandler(e);
      });
      eventableIframes[i].addEventListener('keydown', function (e) {
        shortcutHandler(e);
      });
    }

    // Save the document every 100ms by default
    if (self.settings.file.autoSave) {
      self.saveInterval = window.setInterval(function () {
        if (!self._canSave) {
          return;
        }
        self.save();
      }, self.settings.file.autoSave);
    }

    window.addEventListener('resize', function () {
      // If NOT webkit, and in fullscreen, we need to account for browser resizing
      // we don't care about webkit because you can't resize in webkit's fullscreen
      if (!self.iframe.webkitRequestFullScreen && self.eeState.fullscreen) {
        _applyStyles(self.iframeElement, {
          'width': window.outerWidth + 'px'
        , 'height': window.innerHeight + 'px'
        });

        _applyStyles(self.element, {
          'height': window.innerHeight + 'px'
        });

        _applyStyles(self.previewerIframe, {
          'width': window.outerWidth / 2 + 'px'
        , 'height': window.innerHeight + 'px'
        });

        _applyStyles(self.editorIframe, {
          'width': window.outerWidth / 2 + 'px'
        , 'height': window.innerHeight + 'px'
        });
      }
      // Makes the editor support fluid width when not in fullscreen mode
      else if (!self.eeState.fullscreen) {
        resetWidth(elementsToResize);
      }
    });

    self.iframe.close();
    self.eeState.loaded = true;
    self.eeState.unloaded = false;
    // The callback and call are the same thing, but different ways to access them
    callback.call(this);
    this.emit('load');
    return this;
  }

  /**
   * Will remove the editor, but not offline files
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.unload = function (callback) {

    // Make sure the editor isn't already unloaded.
    if (this.eeState.unloaded) {
      throw new Error('Editor isn\'t loaded');
    }

    var self = this
      , editor = window.parent.document.getElementById(self._instanceId);

    editor.parentNode.removeChild(editor);
    self.eeState.loaded = false;
    self.eeState.unloaded = true;
    callback = callback || function () {};
    
    if (self.saveInterval) {
      window.clearInterval(self.saveInterval);
    }
    
    callback.call(this);
    self.emit('unload');
    return self;
  }

  /**
   * Will take the markdown and generate a preview view based on the theme
   * @param {string} theme The path to the theme you want to preview in
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.preview = function (theme) {
    var self = this;
    
    theme = theme || self.settings.basePath + self.settings.theme.preview;

    _replaceClass(self.getElement('wrapper'), 'epiceditor-edit-mode', 'epiceditor-preview-mode');

    // Check if no CSS theme link exists
    if (!self.previewerIframeDocument.getElementById('theme')) {
      _insertCSSLink(theme, self.previewerIframeDocument, 'theme');
    }
    else if (self.previewerIframeDocument.getElementById('theme').name !== theme) {
      self.previewerIframeDocument.getElementById('theme').href = theme;
    }
    
    // Add the generated HTML into the previewer
    self.previewer.innerHTML = self.exportFile(null, 'html');
    
    // Hide the editor and display the previewer
    if (!self.eeState.fullscreen) {
      self.editorIframe.style.display = 'none';
      self.previewerIframe.style.display = 'block';
      self.eeState.preview = true;
      self.eeState.edit = false;
      self.previewerIframe.focus();
    }
    
    self.emit('preview');
    return self;
  }

  /**
   * Hides the preview and shows the editor again
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.edit = function () {
    var self = this;
    _replaceClass(self.getElement('wrapper'), 'epiceditor-preview-mode', 'epiceditor-edit-mode');
    self.eeState.preview = false;
    self.eeState.edit = true;
    self.editorIframe.style.display = 'block';
    self.previewerIframe.style.display = 'none';
    self.editorIframe.focus();
    self.emit('edit');
    return this;
  }

  /**
   * Grabs a specificed HTML node. Use it as a shortcut to getting the iframe contents
   * @param   {String} name The name of the node (can be document, body, editor, previewer, or wrapper)
   * @returns {Object|Null}
   */
  EpicEditor.prototype.getElement = function (name) {
    var available = {
      "container": this.element
    , "wrapper": this.iframe.getElementById('epiceditor-wrapper')
    , "wrapperIframe": this.iframeElement
    , "editor": this.editorIframeDocument
    , "editorIframe": this.editorIframe
    , "previewer": this.previewerIframeDocument
    , "previewerIframe": this.previewerIframe
    }

    // Check that the given string is a possible option and verify the editor isn't unloaded
    // without this, you'd be given a reference to an object that no longer exists in the DOM
    if (!available[name] || this.eeState.unloaded) {
      return null;
    }
    else {
      return available[name];
    }
  }

  /**
   * Opens a file
   * @param   {string} name The name of the file you want to open
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.open = function (name) {
    var self = this
      , defaultContent = self.settings.file.defaultContent
      , fileObj;
    name = name || self.settings.file.name;
    self.settings.file.name = name;
    if (this._storage[self.settings.localStorageName]) {
      fileObj = self.getFiles();
      if (fileObj[name] !== undefined) {
        _setText(self.editor, fileObj[name].content);
        self.emit('read');
      }
      else {
        _setText(self.editor, defaultContent);
        self.save(); // ensure a save
        self.emit('create');
      }
      self.previewer.innerHTML = self.exportFile(null, 'html');
      self.emit('open');
    }
    return this;
  }

  /**
   * Saves content for offline use
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.save = function () {
    var self = this
      , storage
      , isUpdate = false
      , file = self.settings.file.name
      , content = _getText(this.editor);

    // This could have been false but since we're manually saving
    // we know it's save to start autoSaving again
    this._canSave = true;

    storage = JSON.parse(this._storage[self.settings.localStorageName]);

    // If the file doesn't exist we need to create it
    if (storage[file] === undefined) {
      storage[file] = self._defaultFileSchema();
    }

    // If it does, we need to check if the content is different and
    // if it is, send the update event and update the timestamp
    else if (content !== storage[file].content) {
      storage[file].modified = new Date();
      isUpdate = true;
    }

    storage[file].content = content;
    this._storage[self.settings.localStorageName] = JSON.stringify(storage);

    // After the content is actually changed, emit update so it emits the updated content
    if (isUpdate) {
      self.emit('update');
    }

    this.emit('save');
    return this;
  }

  /**
   * Removes a page
   * @param   {string} name The name of the file you want to remove from localStorage
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.remove = function (name) {
    var self = this
      , s;
    name = name || self.settings.file.name;

    // If you're trying to delete a page you have open, block saving
    if (name == self.settings.file.name) {
      self._canSave = false;
    }

    s = JSON.parse(this._storage[self.settings.localStorageName]);
    delete s[name];
    this._storage[self.settings.localStorageName] = JSON.stringify(s);
    this.emit('remove');
    return this;
  };

  /**
   * Renames a file
   * @param   {string} oldName The old file name
   * @param   {string} newName The new file name
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.rename = function (oldName, newName) {
    var self = this
      , s = JSON.parse(this._storage[self.settings.localStorageName]);
    s[newName] = s[oldName];
    delete s[oldName];
    this._storage[self.settings.localStorageName] = JSON.stringify(s);
    self.open(newName);
    return this;
  };

  /**
   * Imports a file and it's contents and opens it
   * @param   {string} name The name of the file you want to import (will overwrite existing files!)
   * @param   {string} content Content of the file you want to import
   * @param   {string} kind The kind of file you want to import (TBI)
   * @param   {object} meta Meta data you want to save with your file.
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.importFile = function (name, content, kind, meta) {
    var self = this
      , isNew = false;

    name = name || self.settings.file.name;
    content = content || '';
    kind = kind || 'md';
    meta = meta || {};
  
    if (JSON.parse(this._storage[self.settings.localStorageName])[name] === undefined) {
      isNew = true;
    }

    // Set our current file to the new file and update the content
    self.settings.file.name = name;
    _setText(self.editor, content);

    if (isNew) {
      self.emit('create');
    }

    self.save();

    if (self.eeState.fullscreen) {
      self.preview();
    }

    return this;
  };

  /**
   * Exports a file as a string in a supported format
   * @param   {string} name Name of the file you want to export (case sensitive)
   * @param   {string} kind Kind of file you want the content in (currently supports html and text)
   * @returns {string|undefined}  The content of the file in the content given or undefined if it doesn't exist
   */
  EpicEditor.prototype.exportFile = function (name, kind) {
    var self = this
      , file
      , content;

    name = name || self.settings.file.name;
    kind = kind || 'text';
   
    file = self.getFiles(name);

    // If the file doesn't exist just return early with undefined
    if (file === undefined) {
      return;
    }

    content = file.content;
   
    switch (kind) {
    case 'html':
      // Get this, 2 spaces in a content editable actually converts to:
      // 0020 00a0, meaning, "space no-break space". So, manually convert
      // no-break spaces to spaces again before handing to marked.
      // Also, WebKit converts no-break to unicode equivalent and FF HTML.
      content = content.replace(/\u00a0/g, ' ').replace(/&nbsp;/g, ' ');
      return self.settings.parser(content);
    case 'text':
      content = content.replace(/&nbsp;/g, ' ');
      return content;
    default:
      return content;
    }
  }

  EpicEditor.prototype.getFiles = function (name) {
    var files = JSON.parse(this._storage[this.settings.localStorageName]);
    if (name) {
      return files[name];
    }
    else {
      return files;
    }
  }

  // EVENTS
  // TODO: Support for namespacing events like "preview.foo"
  /**
   * Sets up an event handler for a specified event
   * @param  {string} ev The event name
   * @param  {function} handler The callback to run when the event fires
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.on = function (ev, handler) {
    var self = this;
    if (!this.events[ev]) {
      this.events[ev] = [];
    }
    this.events[ev].push(handler);
    return self;
  };

  /**
   * This will emit or "trigger" an event specified
   * @param  {string} ev The event name
   * @param  {any} data Any data you want to pass into the callback
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.emit = function (ev, data) {
    var self = this
      , x;

    data = data || self.getFiles(self.settings.file.name);

    if (!this.events[ev]) {
      return;
    }

    function invokeHandler(handler) {
      handler.call(self, data);
    }

    for (x = 0; x < self.events[ev].length; x++) {
      invokeHandler(self.events[ev][x]);
    }

    return self;
  };

  /**
   * Will remove any listeners added from EpicEditor.on()
   * @param  {string} ev The event name
   * @param  {function} handler Handler to remove
   * @returns {object} EpicEditor will be returned
   */
  EpicEditor.prototype.removeListener = function (ev, handler) {
    var self = this;
    if (!handler) {
      this.events[ev] = [];
      return self;
    }
    if (!this.events[ev]) {
      return self;
    }
    // Otherwise a handler and event exist, so take care of it
    this.events[ev].splice(this.events[ev].indexOf(handler), 1);
    return self;
  }

  EpicEditor.version = '0.1.1.1';

  // Used to store information to be shared acrossed editors
  EpicEditor._data = {};

  window.EpicEditor = EpicEditor;
})(window);

/**
 * marked - A markdown parser (https://github.com/chjj/marked)
 * Copyright (c) 2011-2012, Christopher Jeffrey. (MIT Licensed)
 */

;(function() {

/**
 * Block-Level Grammar
 */

var block = {
  newline: /^\n+/,
  code: /^( {4}[^\n]+\n*)+/,
  fences: noop,
  hr: /^( *[-*_]){3,} *(?:\n+|$)/,
  heading: /^ *(#{1,6}) *([^\n]+?) *#* *(?:\n+|$)/,
  lheading: /^([^\n]+)\n *(=|-){3,} *\n*/,
  blockquote: /^( *>[^\n]+(\n[^\n]+)*\n*)+/,
  list: /^( *)(bull) [^\0]+?(?:hr|\n{2,}(?! )(?!\1bull )\n*|\s*$)/,
  html: /^ *(?:comment|closed|closing) *(?:\n{2,}|\s*$)/,
  def: /^ *\[([^\]]+)\]: *([^\s]+)(?: +["(]([^\n]+)[")])? *(?:\n+|$)/,
  paragraph: /^([^\n]+\n?(?!body))+\n*/,
  text: /^[^\n]+/
};

block.bullet = /(?:[*+-]|\d+\.)/;
block.item = /^( *)(bull) [^\n]*(?:\n(?!\1bull )[^\n]*)*/;
block.item = replace(block.item, 'gm')
  (/bull/g, block.bullet)
  ();

block.list = replace(block.list)
  (/bull/g, block.bullet)
  ('hr', /\n+(?=(?: *[-*_]){3,} *(?:\n+|$))/)
  ();

block.html = replace(block.html)
  ('comment', /<!--[^\0]*?-->/)
  ('closed', /<(tag)[^\0]+?<\/\1>/)
  ('closing', /<tag(?!:\/|@)\b(?:"[^"]*"|'[^']*'|[^'">])*?>/)
  (/tag/g, tag())
  ();

block.paragraph = (function() {
  var paragraph = block.paragraph.source
    , body = [];

  (function push(rule) {
    rule = block[rule] ? block[rule].source : rule;
    body.push(rule.replace(/(^|[^\[])\^/g, '$1'));
    return push;
  })
  ('hr')
  ('heading')
  ('lheading')
  ('blockquote')
  ('<' + tag())
  ('def');

  return new
    RegExp(paragraph.replace('body', body.join('|')));
})();

block.normal = {
  fences: block.fences,
  paragraph: block.paragraph
};

block.gfm = {
  fences: /^ *``` *(\w+)? *\n([^\0]+?)\s*``` *(?:\n+|$)/,
  paragraph: /^/
};

block.gfm.paragraph = replace(block.paragraph)
  ('(?!', '(?!' + block.gfm.fences.source.replace(/(^|[^\[])\^/g, '$1') + '|')
  ();

/**
 * Block Lexer
 */

block.lexer = function(src) {
  var tokens = [];

  tokens.links = {};

  src = src
    .replace(/\r\n|\r/g, '\n')
    .replace(/\t/g, '    ');

  return block.token(src, tokens, true);
};

block.token = function(src, tokens, top) {
  var src = src.replace(/^ +$/gm, '')
    , next
    , loose
    , cap
    , item
    , space
    , i
    , l;

  while (src) {
    // newline
    if (cap = block.newline.exec(src)) {
      src = src.substring(cap[0].length);
      if (cap[0].length > 1) {
        tokens.push({
          type: 'space'
        });
      }
    }

    // code
    if (cap = block.code.exec(src)) {
      src = src.substring(cap[0].length);
      cap = cap[0].replace(/^ {4}/gm, '');
      tokens.push({
        type: 'code',
        text: !options.pedantic
          ? cap.replace(/\n+$/, '')
          : cap
      });
      continue;
    }

    // fences (gfm)
    if (cap = block.fences.exec(src)) {
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'code',
        lang: cap[1],
        text: cap[2]
      });
      continue;
    }

    // heading
    if (cap = block.heading.exec(src)) {
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'heading',
        depth: cap[1].length,
        text: cap[2]
      });
      continue;
    }

    // lheading
    if (cap = block.lheading.exec(src)) {
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'heading',
        depth: cap[2] === '=' ? 1 : 2,
        text: cap[1]
      });
      continue;
    }

    // hr
    if (cap = block.hr.exec(src)) {
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'hr'
      });
      continue;
    }

    // blockquote
    if (cap = block.blockquote.exec(src)) {
      src = src.substring(cap[0].length);

      tokens.push({
        type: 'blockquote_start'
      });

      cap = cap[0].replace(/^ *> ?/gm, '');

      // Pass `top` to keep the current
      // "toplevel" state. This is exactly
      // how markdown.pl works.
      block.token(cap, tokens, top);

      tokens.push({
        type: 'blockquote_end'
      });

      continue;
    }

    // list
    if (cap = block.list.exec(src)) {
      src = src.substring(cap[0].length);

      tokens.push({
        type: 'list_start',
        ordered: isFinite(cap[2])
      });

      // Get each top-level item.
      cap = cap[0].match(block.item);

      next = false;
      l = cap.length;
      i = 0;

      for (; i < l; i++) {
        item = cap[i];

        // Remove the list item's bullet
        // so it is seen as the next token.
        space = item.length;
        item = item.replace(/^ *([*+-]|\d+\.) +/, '');

        // Outdent whatever the
        // list item contains. Hacky.
        if (~item.indexOf('\n ')) {
          space -= item.length;
          item = !options.pedantic
            ? item.replace(new RegExp('^ {1,' + space + '}', 'gm'), '')
            : item.replace(/^ {1,4}/gm, '');
        }

        // Determine whether item is loose or not.
        // Use: /(^|\n)(?! )[^\n]+\n\n(?!\s*$)/
        // for discount behavior.
        loose = next || /\n\n(?!\s*$)/.test(item);
        if (i !== l - 1) {
          next = item[item.length-1] === '\n';
          if (!loose) loose = next;
        }

        tokens.push({
          type: loose
            ? 'loose_item_start'
            : 'list_item_start'
        });

        // Recurse.
        block.token(item, tokens);

        tokens.push({
          type: 'list_item_end'
        });
      }

      tokens.push({
        type: 'list_end'
      });

      continue;
    }

    // html
    if (cap = block.html.exec(src)) {
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'html',
        pre: cap[1] === 'pre',
        text: cap[0]
      });
      continue;
    }

    // def
    if (top && (cap = block.def.exec(src))) {
      src = src.substring(cap[0].length);
      tokens.links[cap[1].toLowerCase()] = {
        href: cap[2],
        title: cap[3]
      };
      continue;
    }

    // top-level paragraph
    if (top && (cap = block.paragraph.exec(src))) {
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'paragraph',
        text: cap[0]
      });
      continue;
    }

    // text
    if (cap = block.text.exec(src)) {
      // Top-level should never reach here.
      src = src.substring(cap[0].length);
      tokens.push({
        type: 'text',
        text: cap[0]
      });
      continue;
    }
  }

  return tokens;
};

/**
 * Inline Processing
 */

var inline = {
  escape: /^\\([\\`*{}\[\]()#+\-.!_>])/,
  autolink: /^<([^ >]+(@|:\/)[^ >]+)>/,
  url: noop,
  tag: /^<!--[^\0]*?-->|^<\/?\w+(?:"[^"]*"|'[^']*'|[^'">])*?>/,
  link: /^!?\[(inside)\]\(href\)/,
  reflink: /^!?\[(inside)\]\s*\[([^\]]*)\]/,
  nolink: /^!?\[((?:\[[^\]]*\]|[^\[\]])*)\]/,
  strong: /^__([^\0]+?)__(?!_)|^\*\*([^\0]+?)\*\*(?!\*)/,
  em: /^\b_((?:__|[^\0])+?)_\b|^\*((?:\*\*|[^\0])+?)\*(?!\*)/,
  code: /^(`+)([^\0]*?[^`])\1(?!`)/,
  br: /^ {2,}\n(?!\s*$)/,
  text: /^[^\0]+?(?=[\\<!\[_*`]| {2,}\n|$)/
};

inline._linkInside = /(?:\[[^\]]*\]|[^\]]|\](?=[^\[]*\]))*/;
inline._linkHref = /\s*<?([^\s]*?)>?(?:\s+['"]([^\0]*?)['"])?\s*/;

inline.link = replace(inline.link)
  ('inside', inline._linkInside)
  ('href', inline._linkHref)
  ();

inline.reflink = replace(inline.reflink)
  ('inside', inline._linkInside)
  ();

inline.normal = {
  url: inline.url,
  strong: inline.strong,
  em: inline.em,
  text: inline.text
};

inline.pedantic = {
  strong: /^__(?=\S)([^\0]*?\S)__(?!_)|^\*\*(?=\S)([^\0]*?\S)\*\*(?!\*)/,
  em: /^_(?=\S)([^\0]*?\S)_(?!_)|^\*(?=\S)([^\0]*?\S)\*(?!\*)/
};

inline.gfm = {
  url: /^(https?:\/\/[^\s]+[^.,:;"')\]\s])/,
  text: /^[^\0]+?(?=[\\<!\[_*`]|https?:\/\/| {2,}\n|$)/
};

/**
 * Inline Lexer
 */

inline.lexer = function(src) {
  var out = ''
    , links = tokens.links
    , link
    , text
    , href
    , cap;

  while (src) {
    // escape
    if (cap = inline.escape.exec(src)) {
      src = src.substring(cap[0].length);
      out += cap[1];
      continue;
    }

    // autolink
    if (cap = inline.autolink.exec(src)) {
      src = src.substring(cap[0].length);
      if (cap[2] === '@') {
        text = cap[1][6] === ':'
          ? mangle(cap[1].substring(7))
          : mangle(cap[1]);
        href = mangle('mailto:') + text;
      } else {
        text = escape(cap[1]);
        href = text;
      }
      out += '<a href="'
        + href
        + '">'
        + text
        + '</a>';
      continue;
    }

    // url (gfm)
    if (cap = inline.url.exec(src)) {
      src = src.substring(cap[0].length);
      text = escape(cap[1]);
      href = text;
      out += '<a href="'
        + href
        + '">'
        + text
        + '</a>';
      continue;
    }

    // tag
    if (cap = inline.tag.exec(src)) {
      src = src.substring(cap[0].length);
      out += options.sanitize
        ? escape(cap[0])
        : cap[0];
      continue;
    }

    // link
    if (cap = inline.link.exec(src)) {
      src = src.substring(cap[0].length);
      out += outputLink(cap, {
        href: cap[2],
        title: cap[3]
      });
      continue;
    }

    // reflink, nolink
    if ((cap = inline.reflink.exec(src))
        || (cap = inline.nolink.exec(src))) {
      src = src.substring(cap[0].length);
      link = (cap[2] || cap[1]).replace(/\s+/g, ' ');
      link = links[link.toLowerCase()];
      if (!link || !link.href) {
        out += cap[0][0];
        src = cap[0].substring(1) + src;
        continue;
      }
      out += outputLink(cap, link);
      continue;
    }

    // strong
    if (cap = inline.strong.exec(src)) {
      src = src.substring(cap[0].length);
      out += '<strong>'
        + inline.lexer(cap[2] || cap[1])
        + '</strong>';
      continue;
    }

    // em
    if (cap = inline.em.exec(src)) {
      src = src.substring(cap[0].length);
      out += '<em>'
        + inline.lexer(cap[2] || cap[1])
        + '</em>';
      continue;
    }

    // code
    if (cap = inline.code.exec(src)) {
      src = src.substring(cap[0].length);
      out += '<code>'
        + escape(cap[2], true)
        + '</code>';
      continue;
    }

    // br
    if (cap = inline.br.exec(src)) {
      src = src.substring(cap[0].length);
      out += '<br>';
      continue;
    }

    // text
    if (cap = inline.text.exec(src)) {
      src = src.substring(cap[0].length);
      out += escape(cap[0]);
      continue;
    }
  }

  return out;
};

function outputLink(cap, link) {
  if (cap[0][0] !== '!') {
    return '<a href="'
      + escape(link.href)
      + '"'
      + (link.title
      ? ' title="'
      + escape(link.title)
      + '"'
      : '')
      + '>'
      + inline.lexer(cap[1])
      + '</a>';
  } else {
    return '<img src="'
      + escape(link.href)
      + '" alt="'
      + escape(cap[1])
      + '"'
      + (link.title
      ? ' title="'
      + escape(link.title)
      + '"'
      : '')
      + '>';
  }
}

/**
 * Parsing
 */

var tokens
  , token;

function next() {
  return token = tokens.pop();
}

function tok() {
  switch (token.type) {
    case 'space': {
      return '';
    }
    case 'hr': {
      return '<hr>\n';
    }
    case 'heading': {
      return '<h'
        + token.depth
        + '>'
        + inline.lexer(token.text)
        + '</h'
        + token.depth
        + '>\n';
    }
    case 'code': {
      if (options.highlight) {
        token.code = options.highlight(token.text, token.lang);
        if (token.code != null && token.code !== token.text) {
          token.escaped = true;
          token.text = token.code;
        }
      }

      if (!token.escaped) {
        token.text = escape(token.text, true);
      }

      return '<pre><code'
        + (token.lang
        ? ' class="lang-'
        + token.lang
        + '"'
        : '')
        + '>'
        + token.text
        + '</code></pre>\n';
    }
    case 'blockquote_start': {
      var body = '';

      while (next().type !== 'blockquote_end') {
        body += tok();
      }

      return '<blockquote>\n'
        + body
        + '</blockquote>\n';
    }
    case 'list_start': {
      var type = token.ordered ? 'ol' : 'ul'
        , body = '';

      while (next().type !== 'list_end') {
        body += tok();
      }

      return '<'
        + type
        + '>\n'
        + body
        + '</'
        + type
        + '>\n';
    }
    case 'list_item_start': {
      var body = '';

      while (next().type !== 'list_item_end') {
        body += token.type === 'text'
          ? parseText()
          : tok();
      }

      return '<li>'
        + body
        + '</li>\n';
    }
    case 'loose_item_start': {
      var body = '';

      while (next().type !== 'list_item_end') {
        body += tok();
      }

      return '<li>'
        + body
        + '</li>\n';
    }
    case 'html': {
      if (options.sanitize) {
        return inline.lexer(token.text);
      }
      return !token.pre && !options.pedantic
        ? inline.lexer(token.text)
        : token.text;
    }
    case 'paragraph': {
      return '<p>'
        + inline.lexer(token.text)
        + '</p>\n';
    }
    case 'text': {
      return '<p>'
        + parseText()
        + '</p>\n';
    }
  }
}

function parseText() {
  var body = token.text
    , top;

  while ((top = tokens[tokens.length-1])
         && top.type === 'text') {
    body += '\n' + next().text;
  }

  return inline.lexer(body);
}

function parse(src) {
  tokens = src.reverse();

  var out = '';
  while (next()) {
    out += tok();
  }

  tokens = null;
  token = null;

  return out;
}

/**
 * Helpers
 */

function escape(html, encode) {
  return html
    .replace(!encode ? /&(?!#?\w+;)/g : /&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function mangle(text) {
  var out = ''
    , l = text.length
    , i = 0
    , ch;

  for (; i < l; i++) {
    ch = text.charCodeAt(i);
    if (Math.random() > 0.5) {
      ch = 'x' + ch.toString(16);
    }
    out += '&#' + ch + ';';
  }

  return out;
}

function tag() {
  var tag = '(?!(?:'
    + 'a|em|strong|small|s|cite|q|dfn|abbr|data|time|code'
    + '|var|samp|kbd|sub|sup|i|b|u|mark|ruby|rt|rp|bdi|bdo'
    + '|span|br|wbr|ins|del|img)\\b)\\w+';

  return tag;
}

function replace(regex, opt) {
  regex = regex.source;
  opt = opt || '';
  return function self(name, val) {
    if (!name) return new RegExp(regex, opt);
    regex = regex.replace(name, val.source || val);
    return self;
  };
}

function noop() {}
noop.exec = noop;

/**
 * Marked
 */

function marked(src, opt) {
  setOptions(opt);
  return parse(block.lexer(src));
}

/**
 * Options
 */

var options
  , defaults;

function setOptions(opt) {
  if (!opt) opt = defaults;
  if (options === opt) return;
  options = opt;

  if (options.gfm) {
    block.fences = block.gfm.fences;
    block.paragraph = block.gfm.paragraph;
    inline.text = inline.gfm.text;
    inline.url = inline.gfm.url;
  } else {
    block.fences = block.normal.fences;
    block.paragraph = block.normal.paragraph;
    inline.text = inline.normal.text;
    inline.url = inline.normal.url;
  }

  if (options.pedantic) {
    inline.em = inline.pedantic.em;
    inline.strong = inline.pedantic.strong;
  } else {
    inline.em = inline.normal.em;
    inline.strong = inline.normal.strong;
  }
}

marked.options =
marked.setOptions = function(opt) {
  defaults = opt;
  setOptions(opt);
  return marked;
};

marked.setOptions({
  gfm: true,
  pedantic: false,
  sanitize: false,
  highlight: null
});

/**
 * Expose
 */

marked.parser = function(src, opt) {
  setOptions(opt);
  return parse(src);
};

marked.lexer = function(src, opt) {
  setOptions(opt);
  return block.lexer(src);
};

marked.parse = marked;

if (typeof module !== 'undefined') {
  module.exports = marked;
} else {
  this.marked = marked;
}

}).call(function() {
  return this || (typeof window !== 'undefined' ? window : global);
}());
