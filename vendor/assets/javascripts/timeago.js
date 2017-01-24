/**
 * Copyright (c) 2016 hustcc
 * License: MIT
 * Version: v2.0.2
 * https://github.com/hustcc/timeago.js
 * This is a forked from (https://gitlab.com/ClemMakesApps/timeago.js)
**/
/* eslint-disable */
/* jshint expr: true */
!function (root, factory) {
  if (typeof module === 'object' && module.exports)
    module.exports = factory(root);
  else
    root.timeago = factory(root);
}(typeof window !== 'undefined' ? window : this,
function () {
  var cnt = 0, // the timer counter, for timer key
    indexMapEn = 'second_minute_hour_day_week_month_year'.split('_'),

    // build-in locales: en & zh_CN
    locales = {
      'en': function(number, index) {
        if (index === 0) return ['just now', 'right now'];
        var unit = indexMapEn[parseInt(index / 2)];
        if (number > 1) unit += 's';
        return [number + ' ' + unit + ' ago', 'in ' + number + ' ' + unit];
      },
    },
    // second, minute, hour, day, week, month, year(365 days)
    SEC_ARRAY = [60, 60, 24, 7, 365/7/12, 12],
    SEC_ARRAY_LEN = 6,
    ATTR_DATETIME = 'datetime';

  // format Date / string / timestamp to Date instance.
  function toDate(input) {
    if (input instanceof Date) return input;
    if (!isNaN(input)) return new Date(toInt(input));
    if (/^\d+$/.test(input)) return new Date(toInt(input, 10));
    input = (input || '').trim().replace(/\.\d+/, '') // remove milliseconds
      .replace(/-/, '/').replace(/-/, '/')
      .replace(/T/, ' ').replace(/Z/, ' UTC')
      .replace(/([\+\-]\d\d)\:?(\d\d)/, ' $1$2'); // -04:00 -> -0400
    return new Date(input);
  }
  // change f into int, remove Decimal. just for code compression
  function toInt(f) {
    return parseInt(f);
  }
  // format the diff second to *** time ago, with setting locale
  function formatDiff(diff, locale, defaultLocale) {
    // if locale is not exist, use defaultLocale.
    // if defaultLocale is not exist, use build-in `en`.
    // be sure of no error when locale is not exist.
    locale = locales[locale] ? locale : (locales[defaultLocale] ? defaultLocale : 'en');
    // if (! locales[locale]) locale = defaultLocale;
    var i = 0;
      agoin = diff < 0 ? 1 : 0; // timein or timeago
    diff = Math.abs(diff);

    for (; diff >= SEC_ARRAY[i] && i < SEC_ARRAY_LEN; i++) {
      diff /= SEC_ARRAY[i];
    }
    diff = toInt(diff);
    i *= 2;

    if (diff > (i === 0 ? 9 : 1)) i += 1;
    return locales[locale](diff, i)[agoin].replace('%s', diff);
  }
  // calculate the diff second between date to be formated an now date.
  function diffSec(date, nowDate) {
    nowDate = nowDate ? toDate(nowDate) : new Date();
    return (nowDate - toDate(date)) / 1000;
  }
  /**
   * nextInterval: calculate the next interval time.
   * - diff: the diff sec between now and date to be formated.
   *
   * What's the meaning?
   * diff = 61 then return 59
   * diff = 3601 (an hour + 1 second), then return 3599
   * make the interval with high performace.
  **/
  function nextInterval(diff) {
    var rst = 1, i = 0, d = Math.abs(diff);
    for (; diff >= SEC_ARRAY[i] && i < SEC_ARRAY_LEN; i++) {
      diff /= SEC_ARRAY[i];
      rst *= SEC_ARRAY[i];
    }
    // return leftSec(d, rst);
    d = d % rst;
    d = d ? rst - d : rst;
    return Math.ceil(d);
  }
  // get the datetime attribute, jQuery and DOM
  function getDateAttr(node) {
    if (node.getAttribute) return node.getAttribute(ATTR_DATETIME);
    if(node.attr) return node.attr(ATTR_DATETIME);
  }
  /**
   * timeago: the function to get `timeago` instance.
   * - nowDate: the relative date, default is new Date().
   * - defaultLocale: the default locale, default is en. if your set it, then the `locale` parameter of format is not needed of you.
   *
   * How to use it?
   * var timeagoLib = require('timeago.js');
   * var timeago = timeagoLib(); // all use default.
   * var timeago = timeagoLib('2016-09-10'); // the relative date is 2016-09-10, so the 2016-09-11 will be 1 day ago.
   * var timeago = timeagoLib(null, 'zh_CN'); // set default locale is `zh_CN`.
   * var timeago = timeagoLib('2016-09-10', 'zh_CN'); // the relative date is 2016-09-10, and locale is zh_CN, so the 2016-09-11 will be 1天前.
  **/
  function Timeago(nowDate, defaultLocale) {
    var timers = {}; // real-time render timers
    // if do not set the defaultLocale, set it with `en`
    if (! defaultLocale) defaultLocale = 'en'; // use default build-in locale
    // what the timer will do
    function doRender(node, date, locale, cnt) {
      var diff = diffSec(date, nowDate);
      node.innerHTML = formatDiff(diff, locale, defaultLocale);
      // waiting %s seconds, do the next render
      timers['k' + cnt] = setTimeout(function() {
        doRender(node, date, locale, cnt);
      }, nextInterval(diff) * 1000);
    }
    /**
     * nextInterval: calculate the next interval time.
     * - diff: the diff sec between now and date to be formated.
     *
     * What's the meaning?
     * diff = 61 then return 59
     * diff = 3601 (an hour + 1 second), then return 3599
     * make the interval with high performace.
    **/
    // this.nextInterval = function(diff) { // for dev test
    //   var rst = 1, i = 0, d = Math.abs(diff);
    //   for (; diff >= SEC_ARRAY[i] && i < SEC_ARRAY_LEN; i++) {
    //     diff /= SEC_ARRAY[i];
    //     rst *= SEC_ARRAY[i];
    //   }
    //   // return leftSec(d, rst);
    //   d = d % rst;
    //   d = d ? rst - d : rst;
    //   return Math.ceil(d);
    // }; // for dev test
    /**
     * format: format the date to *** time ago, with setting or default locale
     * - date: the date / string / timestamp to be formated
     * - locale: the formated string's locale name, e.g. en / zh_CN
     *
     * How to use it?
     * var timeago = require('timeago.js')();
     * timeago.format(new Date(), 'pl'); // Date instance
     * timeago.format('2016-09-10', 'fr'); // formated date string
     * timeago.format(1473473400269); // timestamp with ms
    **/
    this.format = function(date, locale) {
      return formatDiff(diffSec(date, nowDate), locale, defaultLocale);
    };
    /**
     * render: render the DOM real-time.
     * - nodes: which nodes will be rendered.
     * - locale: the locale name used to format date.
     *
     * How to use it?
     * var timeago = new require('timeago.js')();
     * // 1. javascript selector
     * timeago.render(document.querySelectorAll('.need_to_be_rendered'));
     * // 2. use jQuery selector
     * timeago.render($('.need_to_be_rendered'), 'pl');
     *
     * Notice: please be sure the dom has attribute `datetime`.
    **/
    this.render = function(nodes, locale) {
      if (nodes.length === undefined) nodes = [nodes];
      for (var i = 0; i < nodes.length; i++) {
        doRender(nodes[i], getDateAttr(nodes[i]), locale, ++ cnt); // render item
      }
    };
    /**
     * cancel: cancel all the timers which are doing real-time render.
     *
     * How to use it?
     * var timeago = new require('timeago.js')();
     * timeago.render(document.querySelectorAll('.need_to_be_rendered'));
     * timeago.cancel(); // will stop all the timer, stop render in real time.
    **/
    this.cancel = function() {
      for (var key in timers) {
        clearTimeout(timers[key]);
      }
      timers = {};
    };
    /**
     * setLocale: set the default locale name.
     *
     * How to use it?
     * var timeago = require('timeago.js');
     * timeago = new timeago();
     * timeago.setLocale('fr');
    **/
    this.setLocale = function(locale) {
      defaultLocale = locale;
    };
    return this;
  }
  /**
   * timeago: the function to get `timeago` instance.
   * - nowDate: the relative date, default is new Date().
   * - defaultLocale: the default locale, default is en. if your set it, then the `locale` parameter of format is not needed of you.
   *
   * How to use it?
   * var timeagoLib = require('timeago.js');
   * var timeago = timeagoLib(); // all use default.
   * var timeago = timeagoLib('2016-09-10'); // the relative date is 2016-09-10, so the 2016-09-11 will be 1 day ago.
   * var timeago = timeagoLib(null, 'zh_CN'); // set default locale is `zh_CN`.
   * var timeago = timeagoLib('2016-09-10', 'zh_CN'); // the relative date is 2016-09-10, and locale is zh_CN, so the 2016-09-11 will be 1天前.
   **/
  function timeagoFactory(nowDate, defaultLocale) {
    return new Timeago(nowDate, defaultLocale);
  }
  /**
   * register: register a new language locale
   * - locale: locale name, e.g. en / zh_CN, notice the standard.
   * - localeFunc: the locale process function
   *
   * How to use it?
   * var timeagoLib = require('timeago.js');
   *
   * timeagoLib.register('the locale name', the_locale_func);
   * // or
   * timeagoLib.register('pl', require('timeago.js/locales/pl'));
   **/
  timeagoFactory.register = function(locale, localeFunc) {
    locales[locale] = localeFunc;
  };

  return timeagoFactory;
});
