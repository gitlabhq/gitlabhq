var PerformanceBar, ajaxStart, renderPerformanceBar, updateStatus;

PerformanceBar = (function() {
  PerformanceBar.prototype.appInfo = null;

  PerformanceBar.prototype.width = null;

  PerformanceBar.formatTime = function(value) {
    if (value >= 1000) {
      return ((value / 1000).toFixed(3)) + "s";
    } else {
      return (value.toFixed(0)) + "ms";
    }
  };

  function PerformanceBar(options) {
    var k, v;
    if (options == null) {
      options = {};
    }
    this.el = $('#peek-view-performance-bar .performance-bar');
    for (k in options) {
      v = options[k];
      this[k] = v;
    }
    if (this.width == null) {
      this.width = this.el.width();
    }
    if (this.timing == null) {
      this.timing = window.performance.timing;
    }
  }

  PerformanceBar.prototype.render = function(serverTime) {
    var networkTime, perfNetworkTime;
    if (serverTime == null) {
      serverTime = 0;
    }
    this.el.empty();
    this.addBar('frontend', '#90d35b', 'domLoading', 'domInteractive');
    perfNetworkTime = this.timing.responseEnd - this.timing.requestStart;
    if (serverTime && serverTime <= perfNetworkTime) {
      networkTime = perfNetworkTime - serverTime;
      this.addBar('latency / receiving', '#f1faff', this.timing.requestStart + serverTime, this.timing.requestStart + serverTime + networkTime);
      this.addBar('app', '#90afcf', this.timing.requestStart, this.timing.requestStart + serverTime, this.appInfo);
    } else {
      this.addBar('backend', '#c1d7ee', 'requestStart', 'responseEnd');
    }
    this.addBar('tcp / ssl', '#45688e', 'connectStart', 'connectEnd');
    this.addBar('redirect', '#0c365e', 'redirectStart', 'redirectEnd');
    this.addBar('dns', '#082541', 'domainLookupStart', 'domainLookupEnd');
    return this.el;
  };

  PerformanceBar.prototype.isLoaded = function() {
    return this.timing.domInteractive;
  };

  PerformanceBar.prototype.start = function() {
    return this.timing.navigationStart;
  };

  PerformanceBar.prototype.end = function() {
    return this.timing.domInteractive;
  };

  PerformanceBar.prototype.total = function() {
    return this.end() - this.start();
  };

  PerformanceBar.prototype.addBar = function(name, color, start, end, info) {
    var bar, left, offset, time, title, width;
    if (typeof start === 'string') {
      start = this.timing[start];
    }
    if (typeof end === 'string') {
      end = this.timing[end];
    }
    if (!((start != null) && (end != null))) {
      return;
    }
    time = end - start;
    offset = start - this.start();
    left = this.mapH(offset);
    width = this.mapH(time);
    title = name + ": " + (PerformanceBar.formatTime(time));
    bar = $('<li></li>', {
      'data-title': title,
      'data-toggle': 'tooltip',
      'data-container': 'body'
    });
    bar.css({
      width: width + "px",
      left: left + "px",
      background: color
    });
    return this.el.append(bar);
  };

  PerformanceBar.prototype.mapH = function(offset) {
    return offset * (this.width / this.total());
  };

  return PerformanceBar;

})();

renderPerformanceBar = function() {
  var bar, resp, span, time;
  resp = $('#peek-server_response_time');
  time = Math.round(resp.data('time') * 1000);
  bar = new PerformanceBar;
  bar.render(time);
  span = $('<span>', {
    'data-toggle': 'tooltip',
    'data-title': 'Total navigation time for this page.',
    'data-container': 'body'
  }).text(PerformanceBar.formatTime(bar.total()));
  return updateStatus(span);
};

updateStatus = function(html) {
  return $('#serverstats').html(html);
};

ajaxStart = null;

$(document).on('pjax:start page:fetch turbolinks:request-start', function(event) {
  return ajaxStart = event.timeStamp;
});

$(document).on('pjax:end page:load turbolinks:load', function(event, xhr) {
  var ajaxEnd, serverTime, total;
  if (ajaxStart == null) {
    return;
  }
  ajaxEnd = event.timeStamp;
  total = ajaxEnd - ajaxStart;
  serverTime = xhr ? parseInt(xhr.getResponseHeader('X-Runtime')) : 0;
  return setTimeout(function() {
    var bar, now, span, tech;
    now = new Date().getTime();
    bar = new PerformanceBar({
      timing: {
        requestStart: ajaxStart,
        responseEnd: ajaxEnd,
        domLoading: ajaxEnd,
        domInteractive: now
      },
      isLoaded: function() {
        return true;
      },
      start: function() {
        return ajaxStart;
      },
      end: function() {
        return now;
      }
    });
    bar.render(serverTime);
    if ($.fn.pjax != null) {
      tech = 'PJAX';
    } else {
      tech = 'Turbolinks';
    }
    span = $('<span>', {
      'data-toggle': 'tooltip',
      'data-title': tech + " navigation time",
      'data-container': 'body'
    }).text(PerformanceBar.formatTime(total));
    updateStatus(span);
    return ajaxStart = null;
  }, 0);
});

$(function() {
  if (window.performance) {
    return renderPerformanceBar();
  } else {
    return $('#peek-view-performance-bar').remove();
  }
});
