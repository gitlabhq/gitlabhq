/* eslint-disable space-before-function-paren, quotes, comma-dangle, dot-notation, indent, quote-props, no-var, padded-blocks, max-len */

/*= require merge_request_widget */
/*= require lib/utils/datetime_utility */

(function() {
  describe('MergeRequestWidget', function() {
    beforeEach(function() {
      window.notifyPermissions = function() {};
      window.notify = function() {};
      this.opts = {
        ci_status_url: "http://sampledomain.local/ci/getstatus",
        ci_environments_status_url: "http://sampledomain.local/ci/getenvironmentsstatus",
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
    });

    describe('getCIEnvironmentsStatus', function() {
      beforeEach(function() {
        this.ciEnvironmentsStatusData = [{
          created_at: '2016-09-12T13:38:30.636Z',
          environment_id: 1,
          environment_name: 'env1',
          external_url: 'https://test-url.com',
          external_url_formatted: 'test-url.com'
        }];

        spyOn(jQuery, 'getJSON').and.callFake(function(req, cb) {
          cb(this.ciEnvironmentsStatusData);
        }.bind(this));
      });

      it('should call renderEnvironments when the environments property is set', function() {
         const spy = spyOn(this.class, 'renderEnvironments').and.stub();
         this.class.getCIEnvironmentsStatus();
         expect(spy).toHaveBeenCalledWith(this.ciEnvironmentsStatusData);
       });

       it('should not call renderEnvironments when the environments property is not set', function() {
         this.ciEnvironmentsStatusData = null;
         const spy = spyOn(this.class, 'renderEnvironments').and.stub();
         this.class.getCIEnvironmentsStatus();
         expect(spy).not.toHaveBeenCalled();
       });
    });

    describe('renderEnvironments', function() {
      describe('should render correct timeago', function() {
        beforeEach(function() {
          this.environments = [{
            id: 'test-environment-id',
            url: 'testurl',
            deployed_at: new Date().toISOString(),
            deployed_at_formatted: true
          }];
        });

        function getTimeagoText(template) {
          var el = document.createElement('html');
          el.innerHTML = template;
          return el.querySelector('.js-environment-timeago').innerText.trim();
        }

        it('should render less than a minute ago text', function() {
          spyOn(this.class.$widgetBody, 'before').and.callFake(function(template) {
            expect(getTimeagoText(template)).toBe('less than a minute ago.');
          });

          this.class.renderEnvironments(this.environments);
        });

        it('should render about an hour ago text', function() {
          var oneHourAgo = new Date();
          oneHourAgo.setHours(oneHourAgo.getHours() - 1);

          this.environments[0].deployed_at = oneHourAgo.toISOString();
          spyOn(this.class.$widgetBody, 'before').and.callFake(function(template) {
            expect(getTimeagoText(template)).toBe('about an hour ago.');
          });

          this.class.renderEnvironments(this.environments);
        });

        it('should render about 2 hours ago text', function() {
          var twoHoursAgo = new Date();
          twoHoursAgo.setHours(twoHoursAgo.getHours() - 2);

          this.environments[0].deployed_at = twoHoursAgo.toISOString();
          spyOn(this.class.$widgetBody, 'before').and.callFake(function(template) {
            expect(getTimeagoText(template)).toBe('about 2 hours ago.');
          });

          this.class.renderEnvironments(this.environments);
        });
      });
    });

    return describe('getCIStatus', function() {
      beforeEach(function() {
        this.ciStatusData = {
          "title": "Sample MR title",
          "sha": "12a34bc5",
          "status": "success",
          "coverage": 98
        };

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
    });
  });

}).call(this);
