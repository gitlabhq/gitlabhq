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
      this.colors.push(Raphael.getColor(.8));
      // Skipping a few colors in the spectrum to get more contrast between colors
      Raphael.getColor();Raphael.getColor();
    }
  };

  BranchGraph.prototype.buildGraph = function(){
    var graphWidth = $(this.element).width()
      , ch = this.mspace * 20 + 100
      , cw = Math.max(graphWidth, this.mtime * 20 + 260)
      , r = Raphael(this.element.get(0), cw, ch)
      , top = r.set()
      , cuday = 0
      , cumonth = ""
      , offsetX = 20
      , offsetY = 60
      , barWidth = Math.max(graphWidth, this.dayCount * 20 + 320)
      , scrollLeft = cw;
    
    this.raphael = r;
    
    r.rect(0, 0, barWidth, 20).attr({fill: "#222"});
    r.rect(0, 20, barWidth, 20).attr({fill: "#444"});
    
    for (mm = 0; mm < this.dayCount; mm++) {
      if(this.days[mm] != null){
        if(cuday != this.days[mm][0]){
          // Dates
          r.text(offsetX + mm * 20, 31, this.days[mm][0]).attr({
            font: "12px Monaco, monospace",
            fill: "#DDD"
          });
          cuday = this.days[mm][0];
        }
        if(cumonth != this.days[mm][1]){
          // Months
          r.text(offsetX + mm * 20, 11, this.days[mm][1]).attr({
            font: "12px Monaco, monospace", 
            fill: "#EEE"
          });
          cumonth = this.days[mm][1];
        }
      }
    }
    
    for (i = 0; i < this.commitCount; i++) {
      var x = offsetX + 20 * this.commits[i].time
        , y = offsetY + 10 * this.commits[i].space
        , c
        , ps;
      
      // Draw dot
      r.circle(x, y, 3).attr({
        fill: this.colors[this.commits[i].space], 
        stroke: "none"
      });
      
      // Draw lines
      for (var j = 0, jj = this.commits[i].parents.length; j < jj; j++) {
        c = this.preparedCommits[this.commits[i].parents[j][0]];
        ps = this.commits[i].parent_spaces[j];
        if (c) {
          var cx = offsetX + 20 * c.time
            , cy = offsetY + 10 * c.space
            , psy = offsetY + 10 * ps;
          if (c.space == this.commits[i].space && c.space == ps) {
            r.path([
              "M", x, y,
              "L", cx, cy
            ]).attr({
              stroke: this.colors[c.space], 
              "stroke-width": 2
            });

          } else if (c.space < this.commits[i].space) {
            r.path([
                "M", x - 5, y,
                "l-5-2,0,4,5,-2",
                "L", x - 10, y,
                "L", x - 15, psy,
                "L", cx + 5, psy,
                "L", cx, cy])
            .attr({
              stroke: this.colors[this.commits[i].space], 
              "stroke-width": 2
            });
          } else {
            r.path([
                "M", x - 3, y + 6,
                "l-4,3,4,2,0,-5",
                "L", x - 5, y + 10,
                "L", x - 10, psy,
                "L", cx + 5, psy,
                "L", cx, cy])
            .attr({
              stroke: this.colors[c.space], 
              "stroke-width": 2
            });
          }
        }
      }
      
      if (this.commits[i].refs) {
        this.appendLabel(x, y, this.commits[i].refs);

        // The main branch is displayed in the center.
        re = new RegExp('(^| )' + this.options.ref + '( |$)');
        if (this.commits[i].refs.match(re)) {
          scrollLeft = x - graphWidth / 2;
        }
      }
      
      this.appendAnchor(top, this.commits[i], x, y);
    }
    top.toFront();
    this.element.scrollLeft(scrollLeft);
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
  
  BranchGraph.prototype.appendLabel = function(x, y, refs){
    var r = this.raphael
      , shortrefs = refs
      , text, textbox, rect;
    
    if (shortrefs.length > 17){
      // Truncate if longer than 15 chars
      shortrefs = shortrefs.substr(0,15) + "…";
    }
    
    text = r.text(x+5, y+8 + 10, shortrefs).attr({
      font: "10px Monaco, monospace", 
      fill: "#FFF",
      title: refs
    });

    textbox = text.getBBox();
    text.transform([
      't', textbox.height/-4, textbox.width/2 + 5,
      'r90'
    ]);
    
    // Create rectangle based on the size of the textbox
    rect = r.rect(x, y, textbox.width + 15, textbox.height + 5, 4).attr({
      "fill": "#000",
      "fill-opacity": .7,
      "stroke": "none"
    });
    
    triangle = r.path([
      'M', x, y + 5,
      'L', x + 4, y + 15,
      'L', x - 4, y + 15,
      'Z'
    ]).attr({
      "fill": "#000",
      "fill-opacity": .7,
      "stroke": "none"
    });
    
    // Rotate and reposition rectangle over text
    rect.transform([
      'r', 90, x, y,
      't', 15, -9
    ]);
    
    // Set text to front
    text.toFront();
  };
  
  BranchGraph.prototype.appendAnchor = function(top, commit, x, y) {
    var r = this.raphael
      , options = this.options
      , anchor;
    anchor = r.circle(x, y, 10).attr({
      fill: "#000", 
      opacity: 0, 
      cursor: "pointer"
    })
    .click(function(){
      window.open(options.commit_url.replace('%s', commit.id), '_blank');
    })
    .hover(function(){
      this.tooltip = r.commitTooltip(x, y + 5, commit);
      top.push(this.tooltip.insertBefore(this));
    }, function(){
      this.tooltip && this.tooltip.remove() && delete this.tooltip;
    });
    top.push(anchor);
  };
  
  this.BranchGraph = BranchGraph;
  
}(this);
Raphael.fn.commitTooltip = function(x, y, commit){
  var nameText, idText, messageText
    , boxWidth = 300
    , boxHeight = 200;
  
  nameText = this.text(x, y + 10, commit.author.name);
  idText = this.text(x, y + 35, commit.id);
  messageText = this.text(x, y + 50, commit.message);
  
  textSet = this.set(nameText, idText, messageText).attr({
    "text-anchor": "start",
    "font": "12px Monaco, monospace"
  });
  
  nameText.attr({
    "font": "14px Arial",
    "font-weight": "bold"
  });
  
  idText.attr({
    "fill": "#AAA"
  });
  
  textWrap(messageText, boxWidth - 50);

  var rect = this.rect(x - 10, y - 10, boxWidth, 100, 4).attr({
    "fill": "#FFF",
    "stroke": "#000",
    "stroke-linecap": "round",
    "stroke-width": 2
  });
  var tooltip = this.set(rect, textSet);

  rect.attr({
    "height" : tooltip.getBBox().height + 10,
    "width" : tooltip.getBBox().width + 10
  });
  
  tooltip.transform([
    't', 20, 20
  ]);
  
  return tooltip;
};

function textWrap(t, width) {
  var content = t.attr("text");
  var abc = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  t.attr({
    "text" : abc
  });
  var letterWidth = t.getBBox().width / abc.length;
  
  t.attr({
    "text" : content
  });

  var words = content.split(" ");
  var x = 0, s = [];
  for ( var i = 0; i < words.length; i++) {

    var l = words[i].length;
    if (x + (l * letterWidth) > width) {
        s.push("\n");
        x = 0;
    }
    x += l * letterWidth;
    s.push(words[i] + " ");
  }
  t.attr({
    "text" : s.join("")
  });
  var b = t.getBBox()
    , h = Math.abs(b.y2) - Math.abs(b.y) + 1;
  t.attr({
    "y": b.y + h
  });
}
