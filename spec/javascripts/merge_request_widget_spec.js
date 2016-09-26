
/*= require merge_request_widget */
/*= require lib/utils/jquery.timeago.js */

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
      this["class"] = new window.gl.MergeRequestWidget(this.opts);
      return this.ciStatusData = {
        "title": "Sample MR title",
        "sha": "12a34bc5",
        "status": "success",
        "coverage": 98
      };
    });
    return describe('getCIStatus', function() {
      beforeEach(function() {
        spyOn(jQuery, 'getJSON').and.callFake((function(_this) {
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
      it('should not display a notification on the first check after the widget has been created', function() {
        var spy;
        spy = spyOn(window, 'notify');
        this["class"] = new window.gl.MergeRequestWidget(this.opts);
        this["class"].getCIStatus(true);
        return expect(spy).not.toHaveBeenCalled();
      });
      it('should call renderEnvironments when the environments property is set', function() {
        this.ciStatusData.environments = [{
          created_at: '2016-09-12T13:38:30.636Z',
          environment_id: 1,
          environment_name: 'env1',
          external_url: 'https://test-url.com',
          external_url_formatted: 'test-url.com'
        }];
        var spy = spyOn(this['class'], 'renderEnvironments').and.stub();
        this['class'].getCIStatus(false);
        expect(spy).toHaveBeenCalledWith(this.ciStatusData.environments);
      });
      it('should not call renderEnvironments when the environments property is not set', function() {
        var spy = spyOn(this['class'], 'renderEnvironments').and.stub();
        this['class'].getCIStatus(false);
        expect(spy).not.toHaveBeenCalled();
      });
    });
  });

}).call(this);
