!function(){

  var BranchGraph = function(element, url){
    this.element = element;
    this.url = url;
    
    this.comms = {};
    this.mtime = 0;
    this.mspace = 0;
    this.parents = {};
    this.colors = ["#000"];
    
    this.load();
  };
  
  BranchGraph.prototype.load = function(){
    $.ajax({
      url: this.url,
      method: 'get',
      dataType: 'json',
      success: $.proxy(function(data){
        $('.loading', this.element).hide();
        this.prepareData(data.days, data.commits);
        this.buildGraph(this.element.get(0));
      }, this)
    });
  },
  
  BranchGraph.prototype.prepareData = function(days, commits){
    this.days = days;
    this.commits = commits;
    ii = this.commits.length;
    for (var i = 0; i < ii; i++) {
      for (var j = 0, jj = this.commits[i].parents.length; j < jj; j++) {
        this.parents[this.commits[i].parents[j][0]] = true;
      }
      this.mtime = Math.max(this.mtime, this.commits[i].time);
      this.mspace = Math.max(this.mspace, this.commits[i].space);
    }
    this.mtime += 4;
    this.mspace += 10;
    for (i = 0; i < ii; i++) {
      if (this.commits[i].id in this.parents) {
        this.commits[i].isParent = true;
      }
      this.comms[this.commits[i].id] = this.commits[i];
    }
    for (var k = 0; k < this.mspace; k++) {
      this.colors.push(Raphael.getColor());
    }
  };

  BranchGraph.prototype.buildGraph = function(holder){
    var ch = this.mspace * 20 + 20
      , cw = this.mtime * 20 + 20
      , r = Raphael(holder, cw, ch)
      , top = r.set()
      , cuday = 0
      , cumonth = ""
      , r;
    
    this.raphael = r;
    
    r.rect(0, 0, this.days.length * 20 + 80, 30).attr({fill: "#222"});
    r.rect(0, 30, this.days.length * 20 + 80, 20).attr({fill: "#444"});
    
    for (mm = 0; mm < this.days.length; mm++) {
      if(this.days[mm] != null){
        if(cuday != this.days[mm][0]){
          r.text(10 + mm * 20, 40, this.days[mm][0]).attr({
            font: "14px Fontin-Sans, Arial",
            fill: "#DDD"
          });
          cuday = this.days[mm][0];
        }
        if(cumonth != this.days[mm][1]){
          r.text(10 + mm * 20, 15, this.days[mm][1]).attr({
            font: "14px Fontin-Sans, Arial", 
            fill: "#EEE"
          });
          cumonth = this.days[mm][1];
        }
      }
    }
    
    for (i = 0; i < ii; i++) {
      var x = 10 + 20 * this.commits[i].time
        , y = 70 + 20 * this.commits[i].space;
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
        var t = r.text(x+5, y+5, shortrefs).attr({
          font: "12px Fontin-Sans, Arial", fill: "#666",
          title: longrefs, cursor: "pointer", rotation: "90"
        });

        var textbox = t.getBBox();
        t.translate(textbox.height/-4, textbox.width/2);
      }
      for (var j = 0, jj = this.commits[i].parents.length; j < jj; j++) {
        var c = this.comms[this.commits[i].parents[j][0]];
        if (c) {
          var cx = 10 + 20 * c.time
            , cy = 70 + 20 * c.space;
          if (c.space == this.commits[i].space) {
            r.path("M" + (x - 5) + "," + (y + .0001) + "L" + (15 + 20 * c.time) + "," + (y + .0001))
            .attr({
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
    var hw = holder.offsetWidth
      , hh = holder.offsetHeight
      , v = r.rect(hw - 8, 0, 4, Math.pow(hh, 2) / ch, 2).attr({
        fill: "#000", 
        opacity: 0
      })
      , h = r.rect(0, hh - 8, Math.pow(hw, 2) / cw, 4, 2).attr({
        fill: "#000", 
        opacity: 0
      })
      , bars = r.set(v, h)
      , drag
      , dragger = function (event) {
          if (drag) {
            event = event || window.event;
            holder.scrollLeft = drag.sl - (event.clientX - drag.x);
            holder.scrollTop = drag.st - (event.clientY - drag.y);
          }
      };
    holder.onmousedown = function (event) {
      event = event || window.event;
      drag = {
        x: event.clientX, 
        y: event.clientY, 
        st: holder.scrollTop, 
        sl: holder.scrollLeft
      };
      document.onmousemove = dragger;
      bars.animate({opacity: .5}, 300);
    };
    document.onmouseup = function () {
      drag = false;
      document.onmousemove = null;
      bars.animate({opacity: 0}, 300);
    };
      
    $(window).on('keydown', function(event){
      if(event.keyCode == 37){
        holder.scrollLeft -= 50; 
      }
      if(event.keyCode == 39){
        // right
        holder.scrollLeft += 50; 
      }
    });
      
      
    holder.scrollLeft = cw;
  };
  
  BranchGraph.prototype.appendAnchor = function(top, c, x, y) {
    var r = this.raphael;
    top.push(r.circle(x, y, 10).attr({
      fill: "#000", 
      opacity: 0, 
      cursor: "pointer"
    })
    .click(function(){
      location.href = location.href.replace("graph", "commits/" + c.id);
    })
    .hover(function () {
      // Create empty node to convert entities to character
      var s = r.text(100, 100, c.author + "\n \n" + c.id + "\n \n" + c.message).attr({
        fill: "#fff"
      });
      this.popup = r.popupit(x, y + 5, s, 0);
      top.push(this.popup.insertBefore(this));
    }, function () {
      this.popup && this.popup.remove() && delete this.popup;
    }));
  };
  
  this.BranchGraph = BranchGraph;
  
}(this);
Raphael.fn.popupit = function (x, y, set, dir, size) {
    dir = dir == null ? 2 : dir;
    size = size || 5;
    x = Math.round(x);
    y = Math.round(y);
    var mmax = Math.max,
        bb = set.getBBox(),
        w = Math.round(bb.width / 2),
        h = Math.round(bb.height / 2),
        dx = [0, w + size * 2, 0, -w - size * 2],
        dy = [-h * 2 - size * 3, -h - size, 0, -h - size],
        p = ["M", x - dx[dir], y - dy[dir], "l", -size, (dir == 2) * -size, -mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, -size, -size,
            "l", 0, -mmax(h - size, 0), (dir == 3) * -size, -size, (dir == 3) * size, -size, 0, -mmax(h - size, 0), "a", size, size, 0, 0, 1, size, -size,
            "l", mmax(w - size, 0), 0, size, !dir * -size, size, !dir * size, mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, size, size,
            "l", 0, mmax(h - size, 0), (dir == 1) * size, size, (dir == 1) * -size, size, 0, mmax(h - size, 0), "a", size, size, 0, 0, 1, -size, size,
            "l", -mmax(w - size, 0), 0, "z"].join(","),
        xy = [{x: x, y: y + size * 2 + h}, {x: x - size * 2 - w, y: y}, {x: x, y: y - size * 2 - h}, {x: x + size * 2 + w, y: y}][dir];
    set.translate(xy.x - w - bb.x, xy.y - h - bb.y);
    return this.set(this.path(p).attr({fill: "#234", stroke: "none"}).insertBefore(set.node ? set : set[0]), set);
};
Raphael.fn.popup = function (x, y, text, dir, size) {
    dir = dir == null ? 2 : dir > 3 ? 3 : dir;
    size = size || 5;
    text = text || "$9.99";
    var res = this.set(),
        d = 3;
    res.push(this.path().attr({fill: "#000", stroke: "#000"}));
    res.push(this.text(x, y, text).attr(this.g.txtattr).attr({fill: "#fff", "font-family": "Helvetica, Arial"}));
    res.update = function (X, Y, withAnimation) {
        X = X || x;
        Y = Y || y;
        var bb = this[1].getBBox(),
            w = bb.width / 2,
            h = bb.height / 2,
            dx = [0, w + size * 2, 0, -w - size * 2],
            dy = [-h * 2 - size * 3, -h - size, 0, -h - size],
            p = ["M", X - dx[dir], Y - dy[dir], "l", -size, (dir == 2) * -size, -mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, -size, -size,
                "l", 0, -mmax(h - size, 0), (dir == 3) * -size, -size, (dir == 3) * size, -size, 0, -mmax(h - size, 0), "a", size, size, 0, 0, 1, size, -size,
                "l", mmax(w - size, 0), 0, size, !dir * -size, size, !dir * size, mmax(w - size, 0), 0, "a", size, size, 0, 0, 1, size, size,
                "l", 0, mmax(h - size, 0), (dir == 1) * size, size, (dir == 1) * -size, size, 0, mmax(h - size, 0), "a", size, size, 0, 0, 1, -size, size,
                "l", -mmax(w - size, 0), 0, "z"].join(","),
            xy = [{x: X, y: Y + size * 2 + h}, {x: X - size * 2 - w, y: Y}, {x: X, y: Y - size * 2 - h}, {x: X + size * 2 + w, y: Y}][dir];
        xy.path = p;
        if (withAnimation) {
            this.animate(xy, 500, ">");
        } else {
            this.attr(xy);
        }
        return this;
    };
    return res.update(x, y);
};
