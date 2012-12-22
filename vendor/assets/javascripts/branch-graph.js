!function(){

  var BranchGraph = function(element, options){
    this.element = element;
    this.options = options;
    
    this.preparedCommits = {};
    this.mtime = 0;
    this.mspace = 0;
    this.parents = {};
    this.colors = ["#000"];
    
    this.load();
  };
  
  BranchGraph.prototype.load = function(){
    $.ajax({
      url: this.options.url,
      method: 'get',
      dataType: 'json',
      success: $.proxy(function(data){
        $('.loading', this.element).hide();
        this.prepareData(data.days, data.commits);
        this.buildGraph();
      }, this)
    });
  };
  
  BranchGraph.prototype.prepareData = function(days, commits){
    this.days = days;
    this.dayCount = days.length;
    this.commits = commits;
    this.commitCount = commits.length;
    
    this.collectParents();
    
    this.mtime += 4;
    this.mspace += 10;
    for (var i = 0; i < this.commitCount; i++) {
      if (this.commits[i].id in this.parents) {
        this.commits[i].isParent = true;
      }
      this.preparedCommits[this.commits[i].id] = this.commits[i];
    }
    this.collectColors();
  };
  
  BranchGraph.prototype.collectParents = function(){
    for (var i = 0; i < this.commitCount; i++) {
      for (var j = 0, jj = this.commits[i].parents.length; j < jj; j++) {
        this.parents[this.commits[i].parents[j][0]] = true;
      }
      this.mtime = Math.max(this.mtime, this.commits[i].time);
      this.mspace = Math.max(this.mspace, this.commits[i].space);
    }
  };
  
  BranchGraph.prototype.collectColors = function(){
    for (var k = 0; k < this.mspace; k++) {
      this.colors.push(Raphael.getColor());
    }
  };

  BranchGraph.prototype.buildGraph = function(){
    var graphWidth = $(this.element).width()
      , ch = this.mspace * 20 + 20
      , cw = Math.max(graphWidth, this.mtime * 20 + 20)
      , r = Raphael(this.element.get(0), cw, ch)
      , top = r.set()
      , cuday = 0
      , cumonth = ""
      , offsetX = 20
      , offsetY = 60
      , barWidth = Math.max(graphWidth, this.dayCount * 20 + 80);
    
    this.raphael = r;
    
    r.rect(0, 0, barWidth, 20).attr({fill: "#222"});
    r.rect(0, 20, barWidth, 20).attr({fill: "#444"});
    
    for (mm = 0; mm < this.dayCount; mm++) {
      if(this.days[mm] != null){
        if(cuday != this.days[mm][0]){
          // Dates
          r.text(offsetX + mm * 20, 31, this.days[mm][0]).attr({
            font: "12px Monaco, Arial",
            fill: "#DDD"
          });
          cuday = this.days[mm][0];
        }
        if(cumonth != this.days[mm][1]){
          // Months
          r.text(offsetX + mm * 20, 11, this.days[mm][1]).attr({
            font: "12px Monaco, Arial", 
            fill: "#EEE"
          });
          cumonth = this.days[mm][1];
        }
      }
    }
    
    for (i = 0; i < this.commitCount; i++) {
      var x = offsetX + 20 * this.commits[i].time
        , y = offsetY + 20 * this.commits[i].space;
      r.circle(x, y, 3).attr({
        fill: this.colors[this.commits[i].space], 
        stroke: "none"
      });
      if (this.commits[i].refs != null && this.commits[i].refs != "") {
        var longrefs = this.commits[i].refs
          , shortrefs = this.commits[i].refs;
        if (shortrefs.length > 15){
          shortrefs = shortrefs.substr(0,13) + "...";
        }
        var t = r.text(x+5, y+8, shortrefs).attr({
          font: "12px Monaco, Arial", 
          fill: "#666",
          title: longrefs, 
          cursor: "pointer", 
          rotation: "90"
        });

        var textbox = t.getBBox();
        t.translate(textbox.height/-4, textbox.width/2);
      }
      var c;
      for (var j = 0, jj = this.commits[i].parents.length; j < jj; j++) {
        c = this.preparedCommits[this.commits[i].parents[j][0]];
        if (c) {
          var cx = offsetX + 20 * c.time
            , cy = offsetY + 20 * c.space;
          if (c.space == this.commits[i].space) {
            r.path([
              "M", x, y,
              "L", x - 20 * (c.time + 1), y
            ]).attr({
              stroke: this.colors[c.space], 
              "stroke-width": 2
            });

          } else if (c.space < this.commits[i].space) {
            r.path(["M", x - 5, y + .0001, "l-5-2,0,4,5,-2C", x - 5, y, x - 17, y + 2, x - 20, y - 5, "L", cx, y - 5, cx, cy])
            .attr({
              stroke: this.colors[this.commits[i].space], 
              "stroke-width": 2
            });
          } else {
            r.path(["M", x - 3, y + 6, "l-4,3,4,2,0,-5L", x - 10, y + 20, "L", x - 10, cy, cx, cy])
            .attr({
              stroke: this.colors[c.space], 
              "stroke-width": 2
            });
          }
        }
      }
      this.appendAnchor(top, this.commits[i], x, y);
    }
    top.toFront();
    this.element.scrollLeft(cw);
    this.bindEvents();
  };
  
  BranchGraph.prototype.bindEvents = function(){
    var drag = {}
      , element = this.element;
      
    var dragger = function(event){
      element.scrollLeft(drag.sl - (event.clientX - drag.x));
      element.scrollTop(drag.st - (event.clientY - drag.y));
    };
    
    element.on({
      mousedown: function (event) {
        drag = {
          x: event.clientX, 
          y: event.clientY, 
          st: element.scrollTop(), 
          sl: element.scrollLeft()
        };
        $(window).on('mousemove', dragger);
      }
    });
    $(window).on({
      mouseup: function(){
        //bars.animate({opacity: 0}, 300);
        $(window).off('mousemove', dragger);
      },
      keydown: function(event){
        if(event.keyCode == 37){
          // left
          element.scrollLeft( element.scrollLeft() - 50); 
        }
        if(event.keyCode == 38){
          // top
          element.scrollTop( element.scrollTop() - 50); 
        }
        if(event.keyCode == 39){
          // right
          element.scrollLeft( element.scrollLeft() + 50); 
        }
        if(event.keyCode == 40){
          // bottom
          element.scrollTop( element.scrollTop() + 50); 
        }
      }
    });
  };
  
  BranchGraph.prototype.appendAnchor = function(top, c, x, y) {
    var r = this.raphael
      , options = this.options
      , anchor;
    anchor = r.circle(x, y, 10).attr({
      fill: "#000", 
      opacity: 0, 
      cursor: "pointer"
    })
    .click(function(){
      window.location = options.commit_url.replace('%s', c.id);
    })
    .hover(function(){
      var text = r.text(100, 100, c.author + "\n \n" + c.id + "\n \n" + c.message).attr({
        fill: "#fff"
      });
      this.popup = r.tooltip(x, y + 5, text, 0);
      top.push(this.popup.insertBefore(this));
    }, function(){
      this.popup && this.popup.remove() && delete this.popup;
    });
    top.push(anchor);
  };
  
  this.BranchGraph = BranchGraph;
  
}(this);
Raphael.fn.tooltip = function (x, y, set, dir, size) {
  dir = dir == null ? 2 : dir;
  size = size || 5;
  x = Math.round(x);
  y = Math.round(y);
  var mmax = Math.max
    , bb = set.getBBox()
    , w = Math.round(bb.width / 2)
    , h = Math.round(bb.height / 2)
    , dx = [0, w + size * 2, 0, -w - size * 2]
    , dy = [-h * 2 - size * 3, -h - size, 0, -h - size]
    , p = ["M", x - dx[dir], y - dy[dir], "l", -size, (dir == 2) * -size, -mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, -size, -size,
          "l", 0, -mmax(h - size, 0), (dir == 3) * -size, -size, (dir == 3) * size, -size, 0, -mmax(h - size, 0), "a", size, size, 0, 0, 1, size, -size,
          "l", mmax(w - size, 0), 0, size, !dir * -size, size, !dir * size, mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, size, size,
          "l", 0, mmax(h - size, 0), (dir == 1) * size, size, (dir == 1) * -size, size, 0, mmax(h - size, 0), "a", size, size, 0, 0, 1, -size, size,
          "l", -mmax(w - size, 0), 0, "z"].join(",")
    , xy = [{x: x, y: y + size * 2 + h}, {x: x - size * 2 - w, y: y}, {x: x, y: y - size * 2 - h}, {x: x + size * 2 + w, y: y}][dir];
  set.translate(xy.x - w - bb.x, xy.y - h - bb.y);
  return this.set(this.path(p).attr({fill: "#234", stroke: "none"}).insertBefore(set.node ? set : set[0]), set);
};
