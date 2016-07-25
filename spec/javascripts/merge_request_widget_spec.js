
/*= require merge_request_widget */

(function() {
  describe('MergeRequestWidget', function() {
    beforeEach(function() {
      window.notifyPermissions = function() {};
      window.notify = function() {};
      this.opts = {
        ci_status_url: "http://sampledomain.local/ci/getstatus",
        ci_status: "",
        ci_message: {
          normal: "Build {{status}} for \"{{title}}\"",
          preparing: "{{status}} build for \"{{title}}\""
        },
        ci_title: {
          preparing: "{{status}} build",
          normal: "Build {{status}}"
        },
        gitlab_icon: "gitlab_logo.png",
        builds_path: "http://sampledomain.local/sampleBuildsPath"
      };
      this["class"] = new MergeRequestWidget(this.opts);
      return this.ciStatusData = {
        "title": "Sample MR title",
        "sha": "12a34bc5",
        "status": "success",
        "coverage": 98
      };
    });
    return describe('getCIStatus', function() {
      beforeEach(function() {
        return spyOn(jQuery, 'getJSON').and.callFake((function(_this) {
          return function(req, cb) {
            return cb(_this.ciStatusData);
          };
        })(this));
      });
      it('should call showCIStatus even if a notification should not be displayed', function() {
        var spy;
        spy = spyOn(this["class"], 'showCIStatus').and.stub();
        this["class"].getCIStatus(false);
        return expect(spy).toHaveBeenCalledWith(this.ciStatusData.status);
      });
      it('should call showCIStatus when a notification should be displayed', function() {
        var spy;
        spy = spyOn(this["class"], 'showCIStatus').and.stub();
        this["class"].getCIStatus(true);
        return expect(spy).toHaveBeenCalledWith(this.ciStatusData.status);
      });
      it('should call showCICoverage when the coverage rate is set', function() {
        var spy;
        spy = spyOn(this["class"], 'showCICoverage').and.stub();
        this["class"].getCIStatus(false);
        return expect(spy).toHaveBeenCalledWith(this.ciStatusData.coverage);
      });
      it('should not call showCICoverage when the coverage rate is not set', function() {
        var spy;
        this.ciStatusData.coverage = null;
        spy = spyOn(this["class"], 'showCICoverage').and.stub();
        this["class"].getCIStatus(false);
        return expect(spy).not.toHaveBeenCalled();
      });
      return it('should not display a notification on the first check after the widget has been created', function() {
        var spy;
        spy = spyOn(window, 'notify');
        this["class"] = new MergeRequestWidget(this.opts);
        this["class"].getCIStatus(true);
        return expect(spy).not.toHaveBeenCalled();
      });
    });
  });

}).call(this);
