/*!
 * jQuery Password Strength plugin for Twitter Bootstrap
 *
 * Copyright (c) 2008-2013 Tane Piper
 * Copyright (c) 2013 Alejandro Blanco
 * Dual licensed under the MIT and GPL licenses.
 */

(function (jQuery) {
// Source: src/rules.js

  var rulesEngine = {};

  try {
    if (!jQuery && module && module.exports) {
      var jQuery = require("jquery"),
        jsdom = require("jsdom").jsdom;
      jQuery = jQuery(jsdom().parentWindow);
    }
  } catch (ignore) {}

  (function ($, rulesEngine) {
    "use strict";
    var validation = {};

    rulesEngine.forbiddenSequences = [
      "0123456789", "abcdefghijklmnopqrstuvwxyz", "qwertyuiop", "asdfghjkl",
      "zxcvbnm", "!@#$%^&*()_+"
    ];

    validation.wordNotEmail = function (options, word, score) {
      if (word.match(/^([\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+\.)*[\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+@((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z])\.)+[a-z]{2,6})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)$/i)) {
        return score;
      }
      return 0;
    };

    validation.wordLength = function (options, word, score) {
      var wordlen = word.length,
        lenScore = Math.pow(wordlen, options.rules.raisePower);
      if (wordlen < options.common.minChar) {
        lenScore = (lenScore + score);
      }
      return lenScore;
    };

    validation.wordSimilarToUsername = function (options, word, score) {
      var username = $(options.common.usernameField).val();
      if (username && word.toLowerCase().match(username.toLowerCase())) {
        return score;
      }
      return 0;
    };

    validation.wordTwoCharacterClasses = function (options, word, score) {
      if (word.match(/([a-z].*[A-Z])|([A-Z].*[a-z])/) ||
        (word.match(/([a-zA-Z])/) && word.match(/([0-9])/)) ||
        (word.match(/(.[!,@,#,$,%,\^,&,*,?,_,~])/) && word.match(/[a-zA-Z0-9_]/))) {
        return score;
      }
      return 0;
    };

    validation.wordRepetitions = function (options, word, score) {
      if (word.match(/(.)\1\1/)) { return score; }
      return 0;
    };

    validation.wordSequences = function (options, word, score) {
      var found = false,
        j;
      if (word.length > 2) {
        $.each(rulesEngine.forbiddenSequences, function (idx, seq) {
          var sequences = [seq, seq.split('').reverse().join('')];
          $.each(sequences, function (idx, sequence) {
            for (j = 0; j < (word.length - 2); j += 1) { // iterate the word trough a sliding window of size 3:
              if (sequence.indexOf(word.toLowerCase().substring(j, j + 3)) > -1) {
                found = true;
              }
            }
          });
        });
        if (found) { return score; }
      }
      return 0;
    };

    validation.wordLowercase = function (options, word, score) {
      return word.match(/[a-z]/) && score;
    };

    validation.wordUppercase = function (options, word, score) {
      return word.match(/[A-Z]/) && score;
    };

    validation.wordOneNumber = function (options, word, score) {
      return word.match(/\d+/) && score;
    };

    validation.wordThreeNumbers = function (options, word, score) {
      return word.match(/(.*[0-9].*[0-9].*[0-9])/) && score;
    };

    validation.wordOneSpecialChar = function (options, word, score) {
      return word.match(/.[!,@,#,$,%,\^,&,*,?,_,~]/) && score;
    };

    validation.wordTwoSpecialChar = function (options, word, score) {
      return word.match(/(.*[!,@,#,$,%,\^,&,*,?,_,~].*[!,@,#,$,%,\^,&,*,?,_,~])/) && score;
    };

    validation.wordUpperLowerCombo = function (options, word, score) {
      return word.match(/([a-z].*[A-Z])|([A-Z].*[a-z])/) && score;
    };

    validation.wordLetterNumberCombo = function (options, word, score) {
      return word.match(/([a-zA-Z])/) && word.match(/([0-9])/) && score;
    };

    validation.wordLetterNumberCharCombo = function (options, word, score) {
      return word.match(/([a-zA-Z0-9].*[!,@,#,$,%,\^,&,*,?,_,~])|([!,@,#,$,%,\^,&,*,?,_,~].*[a-zA-Z0-9])/) && score;
    };

    rulesEngine.validation = validation;

    rulesEngine.executeRules = function (options, word) {
      var totalScore = 0;

      $.each(options.rules.activated, function (rule, active) {
        if (active) {
          var score = options.rules.scores[rule],
            funct = rulesEngine.validation[rule],
            result,
            errorMessage;

          if (!$.isFunction(funct)) {
            funct = options.rules.extra[rule];
          }

          if ($.isFunction(funct)) {
            result = funct(options, word, score);
            if (result) {
              totalScore += result;
            }
            if (result < 0 || (!$.isNumeric(result) && !result)) {
              errorMessage = options.ui.spanError(options, rule);
              if (errorMessage.length > 0) {
                options.instances.errors.push(errorMessage);
              }
            }
          }
        }
      });

      return totalScore;
    };
  }(jQuery, rulesEngine));

  try {
    if (module && module.exports) {
      module.exports = rulesEngine;
    }
  } catch (ignore) {}

// Source: src/options.js




  var defaultOptions = {};

  defaultOptions.common = {};
  defaultOptions.common.minChar = 6;
  defaultOptions.common.usernameField = "#username";
  defaultOptions.common.userInputs = [
    // Selectors for input fields with user input
  ];
  defaultOptions.common.onLoad = undefined;
  defaultOptions.common.onKeyUp = undefined;
  defaultOptions.common.zxcvbn = false;
  defaultOptions.common.debug = false;

  defaultOptions.rules = {};
  defaultOptions.rules.extra = {};
  defaultOptions.rules.scores = {
    wordNotEmail: -100,
    wordLength: -50,
    wordSimilarToUsername: -100,
    wordSequences: -50,
    wordTwoCharacterClasses: 2,
    wordRepetitions: -25,
    wordLowercase: 1,
    wordUppercase: 3,
    wordOneNumber: 3,
    wordThreeNumbers: 5,
    wordOneSpecialChar: 3,
    wordTwoSpecialChar: 5,
    wordUpperLowerCombo: 2,
    wordLetterNumberCombo: 2,
    wordLetterNumberCharCombo: 2
  };
  defaultOptions.rules.activated = {
    wordNotEmail: true,
    wordLength: true,
    wordSimilarToUsername: true,
    wordSequences: true,
    wordTwoCharacterClasses: false,
    wordRepetitions: false,
    wordLowercase: true,
    wordUppercase: true,
    wordOneNumber: true,
    wordThreeNumbers: true,
    wordOneSpecialChar: true,
    wordTwoSpecialChar: true,
    wordUpperLowerCombo: true,
    wordLetterNumberCombo: true,
    wordLetterNumberCharCombo: true
  };
  defaultOptions.rules.raisePower = 1.4;

  defaultOptions.ui = {};
  defaultOptions.ui.bootstrap2 = false;
  defaultOptions.ui.showProgressBar = true;
  defaultOptions.ui.showPopover = false;
  defaultOptions.ui.showStatus = false;
  defaultOptions.ui.spanError = function (options, key) {
    "use strict";
    var text = options.ui.errorMessages[key];
    if (!text) { return ''; }
    return '<span style="color: #d52929">' + text + '</span>';
  };
  defaultOptions.ui.errorMessages = {
    wordLength: "Your password is too short",
    wordNotEmail: "Do not use your email as your password",
    wordSimilarToUsername: "Your password cannot contain your username",
    wordTwoCharacterClasses: "Use different character classes",
    wordRepetitions: "Too many repetitions",
    wordSequences: "Your password contains sequences"
  };
  defaultOptions.ui.verdicts = ["Weak", "Normal", "Medium", "Strong", "Very Strong"];
  defaultOptions.ui.showVerdicts = true;
  defaultOptions.ui.showVerdictsInsideProgressBar = false;
  defaultOptions.ui.showErrors = false;
  defaultOptions.ui.container = undefined;
  defaultOptions.ui.viewports = {
    progress: undefined,
    verdict: undefined,
    errors: undefined
  };
  defaultOptions.ui.scores = [14, 26, 38, 50];

// Source: src/ui.js




  var ui = {};

  (function ($, ui) {
    "use strict";

    var barClasses = ["danger", "warning", "success"],
      statusClasses = ["error", "warning", "success"];

    ui.getContainer = function (options, $el) {
      var $container;

      $container = $(options.ui.container);
      if (!($container && $container.length === 1)) {
        $container = $el.parent();
      }
      return $container;
    };

    ui.findElement = function ($container, viewport, cssSelector) {
      if (viewport) {
        return $container.find(viewport).find(cssSelector);
      }
      return $container.find(cssSelector);
    };

    ui.getUIElements = function (options, $el) {
      var $container, result;

      if (options.instances.viewports) {
        return options.instances.viewports;
      }

      $container = ui.getContainer(options, $el);

      result = {};
      result.$progressbar = ui.findElement($container, options.ui.viewports.progress, "div.progress");
      if (options.ui.showVerdictsInsideProgressBar) {
        result.$verdict = result.$progressbar.find("span.password-verdict");
      }

      if (!options.ui.showPopover) {
        if (!options.ui.showVerdictsInsideProgressBar) {
          result.$verdict = ui.findElement($container, options.ui.viewports.verdict, "span.password-verdict");
        }
        result.$errors = ui.findElement($container, options.ui.viewports.errors, "ul.error-list");
      }

      options.instances.viewports = result;
      return result;
    };

    ui.initProgressBar = function (options, $el) {
      var $container = ui.getContainer(options, $el),
        progressbar = "<div class='progress'><div class='";

      if (!options.ui.bootstrap2) {
        progressbar += "progress-";
      }
      progressbar += "bar'>";
      if (options.ui.showVerdictsInsideProgressBar) {
        progressbar += "<span class='password-verdict'></span>";
      }
      progressbar += "</div></div>";

      if (options.ui.viewports.progress) {
        $container.find(options.ui.viewports.progress).append(progressbar);
      } else {
        $(progressbar).insertAfter($el);
      }
    };

    ui.initHelper = function (options, $el, html, viewport) {
      var $container = ui.getContainer(options, $el);
      if (viewport) {
        $container.find(viewport).append(html);
      } else {
        $(html).insertAfter($el);
      }
    };

    ui.initVerdict = function (options, $el) {
      ui.initHelper(options, $el, "<span class='password-verdict'></span>",
        options.ui.viewports.verdict);
    };

    ui.initErrorList = function (options, $el) {
      ui.initHelper(options, $el, "<ul class='error-list'></ul>",
        options.ui.viewports.errors);
    };

    ui.initPopover = function (options, $el) {
      $el.popover("destroy");
      $el.popover({
        html: true,
        placement: "top",
        trigger: "manual",
        content: " "
      });
    };

    ui.initUI = function (options, $el) {
      if (options.ui.showPopover) {
        ui.initPopover(options, $el);
      } else {
        if (options.ui.showErrors) { ui.initErrorList(options, $el); }
        if (options.ui.showVerdicts && !options.ui.showVerdictsInsideProgressBar) {
          ui.initVerdict(options, $el);
        }
      }
      if (options.ui.showProgressBar) {
        ui.initProgressBar(options, $el);
      }
    };

    ui.possibleProgressBarClasses = ["danger", "warning", "success"];

    ui.updateProgressBar = function (options, $el, cssClass, percentage) {
      var $progressbar = ui.getUIElements(options, $el).$progressbar,
        $bar = $progressbar.find(".progress-bar"),
        cssPrefix = "progress-";

      if (options.ui.bootstrap2) {
        $bar = $progressbar.find(".bar");
        cssPrefix = "";
      }

      $.each(ui.possibleProgressBarClasses, function (idx, value) {
        $bar.removeClass(cssPrefix + "bar-" + value);
      });
      $bar.addClass(cssPrefix + "bar-" + barClasses[cssClass]);
      $bar.css("width", percentage + '%');
    };

    ui.updateVerdict = function (options, $el, text) {
      var $verdict = ui.getUIElements(options, $el).$verdict;
      $verdict.text(text);
    };

    ui.updateErrors = function (options, $el) {
      var $errors = ui.getUIElements(options, $el).$errors,
        html = "";
      $.each(options.instances.errors, function (idx, err) {
        html += "<li>" + err + "</li>";
      });
      $errors.html(html);
    };

    ui.updatePopover = function (options, $el, verdictText) {
      var popover = $el.data("bs.popover"),
        html = "",
        hide = true;

      if (options.ui.showVerdicts &&
        !options.ui.showVerdictsInsideProgressBar &&
        verdictText.length > 0) {
        html = "<h5><span class='password-verdict'>" + verdictText +
          "</span></h5>";
        hide = false;
      }
      if (options.ui.showErrors) {
        html += "<div><ul class='error-list' style='margin-bottom: 0; margin-left: -20px'>";
        $.each(options.instances.errors, function (idx, err) {
          html += "<li>" + err + "</li>";
          hide = false;
        });
        html += "</ul></div>";
      }

      if (hide) {
        $el.popover("hide");
        return;
      }

      if (options.ui.bootstrap2) { popover = $el.data("popover"); }

      if (popover.$arrow && popover.$arrow.parents("body").length > 0) {
        $el.find("+ .popover .popover-content").html(html);
      } else {
        // It's hidden
        popover.options.content = html;
        $el.popover("show");
      }
    };

    ui.updateFieldStatus = function (options, $el, cssClass) {
      var targetClass = options.ui.bootstrap2 ? ".control-group" : ".form-group",
        $container = $el.parents(targetClass).first();

      $.each(statusClasses, function (idx, css) {
        if (!options.ui.bootstrap2) { css = "has-" + css; }
        $container.removeClass(css);
      });

      cssClass = statusClasses[cssClass];
      if (!options.ui.bootstrap2) { cssClass = "has-" + cssClass; }
      $container.addClass(cssClass);
    };

    ui.percentage = function (score, maximun) {
      var result = Math.floor(100 * score / maximun);
      result = result < 0 ? 0 : result;
      result = result > 100 ? 100 : result;
      return result;
    };

    ui.getVerdictAndCssClass = function (options, score) {
      var cssClass, verdictText, level;

      if (score <= 0) {
        cssClass = 0;
        level = -1;
        verdictText = options.ui.verdicts[0];
      } else if (score < options.ui.scores[0]) {
        cssClass = 0;
        level = 0;
        verdictText = options.ui.verdicts[0];
      } else if (score < options.ui.scores[1]) {
        cssClass = 0;
        level = 1;
        verdictText = options.ui.verdicts[1];
      } else if (score < options.ui.scores[2]) {
        cssClass = 1;
        level = 2;
        verdictText = options.ui.verdicts[2];
      } else if (score < options.ui.scores[3]) {
        cssClass = 1;
        level = 3;
        verdictText = options.ui.verdicts[3];
      } else {
        cssClass = 2;
        level = 4;
        verdictText = options.ui.verdicts[4];
      }

      return [verdictText, cssClass, level];
    };

    ui.updateUI = function (options, $el, score) {
      var cssClass, barPercentage, verdictText;

      cssClass = ui.getVerdictAndCssClass(options, score);
      verdictText = cssClass[0];
      cssClass = cssClass[1];

      if (options.ui.showProgressBar) {
        barPercentage = ui.percentage(score, options.ui.scores[3]);
        ui.updateProgressBar(options, $el, cssClass, barPercentage);
        if (options.ui.showVerdictsInsideProgressBar) {
          ui.updateVerdict(options, $el, verdictText);
        }
      }

      if (options.ui.showStatus) {
        ui.updateFieldStatus(options, $el, cssClass);
      }

      if (options.ui.showPopover) {
        ui.updatePopover(options, $el, verdictText);
      } else {
        if (options.ui.showVerdicts && !options.ui.showVerdictsInsideProgressBar) {
          ui.updateVerdict(options, $el, verdictText);
        }
        if (options.ui.showErrors) {
          ui.updateErrors(options, $el);
        }
      }
    };
  }(jQuery, ui));

// Source: src/methods.js




  var methods = {};

  (function ($, methods) {
    "use strict";
    var onKeyUp, applyToAll;

    onKeyUp = function (event) {
      var $el = $(event.target),
        options = $el.data("pwstrength-bootstrap"),
        word = $el.val(),
        userInputs,
        verdictText,
        verdictLevel,
        score;

      if (options === undefined) { return; }

      options.instances.errors = [];
      if (options.common.zxcvbn) {
        userInputs = [];
        $.each(options.common.userInputs, function (idx, selector) {
          userInputs.push($(selector).val());
        });
        userInputs.push($(options.common.usernameField).val());
        score = zxcvbn(word, userInputs).entropy;
      } else {
        score = rulesEngine.executeRules(options, word);
      }
      ui.updateUI(options, $el, score);
      verdictText = ui.getVerdictAndCssClass(options, score);
      verdictLevel = verdictText[2];
      verdictText = verdictText[0];

      if (options.common.debug) { console.log(score + ' - ' + verdictText); }

      if ($.isFunction(options.common.onKeyUp)) {
        options.common.onKeyUp(event, {
          score: score,
          verdictText: verdictText,
          verdictLevel: verdictLevel
        });
      }
    };

    methods.init = function (settings) {
      this.each(function (idx, el) {
        // Make it deep extend (first param) so it extends too the
        // rules and other inside objects
        var clonedDefaults = $.extend(true, {}, defaultOptions),
          localOptions = $.extend(true, clonedDefaults, settings),
          $el = $(el);

        localOptions.instances = {};
        $el.data("pwstrength-bootstrap", localOptions);
        $el.on("keyup", onKeyUp);
        $el.on("change", onKeyUp);
        $el.on("onpaste", onKeyUp);

        ui.initUI(localOptions, $el);
        if ($.trim($el.val())) { // Not empty, calculate the strength
          $el.trigger("keyup");
        }

        if ($.isFunction(localOptions.common.onLoad)) {
          localOptions.common.onLoad();
        }
      });

      return this;
    };

    methods.destroy = function () {
      this.each(function (idx, el) {
        var $el = $(el),
          options = $el.data("pwstrength-bootstrap"),
          elements = ui.getUIElements(options, $el);
        elements.$progressbar.remove();
        elements.$verdict.remove();
        elements.$errors.remove();
        $el.removeData("pwstrength-bootstrap");
      });
    };

    methods.forceUpdate = function () {
      this.each(function (idx, el) {
        var event = { target: el };
        onKeyUp(event);
      });
    };

    methods.addRule = function (name, method, score, active) {
      this.each(function (idx, el) {
        var options = $(el).data("pwstrength-bootstrap");

        options.rules.activated[name] = active;
        options.rules.scores[name] = score;
        options.rules.extra[name] = method;
      });
    };

    applyToAll = function (rule, prop, value) {
      this.each(function (idx, el) {
        $(el).data("pwstrength-bootstrap").rules[prop][rule] = value;
      });
    };

    methods.changeScore = function (rule, score) {
      applyToAll.call(this, rule, "scores", score);
    };

    methods.ruleActive = function (rule, active) {
      applyToAll.call(this, rule, "activated", active);
    };

    $.fn.pwstrength = function (method) {
      var result;

      if (methods[method]) {
        result = methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
      } else if (typeof method === "object" || !method) {
        result = methods.init.apply(this, arguments);
      } else {
        $.error("Method " +  method + " does not exist on jQuery.pwstrength-bootstrap");
      }

      return result;
    };
  }(jQuery, methods));
}(jQuery));