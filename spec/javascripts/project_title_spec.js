/* eslint-disable space-before-function-paren, no-unused-expressions, no-return-assign, no-param-reassign, no-var, new-cap, wrap-iife, no-unused-vars, quotes, jasmine/no-expect-in-setup-teardown, padded-blocks, max-len */

/* global Project */

/*= require bootstrap */
/*= require select2 */
/*= require lib/utils/type_utility */
/*= require gl_dropdown */
/*= require api */
/*= require project_select */
/*= require project */

(function() {
  window.gon || (window.gon = {});

  window.gon.api_version = 'v3';

  describe('Project Title', function() {
    fixture.preload('project_title.html');
    fixture.preload('projects.json');
    beforeEach(function() {
      fixture.load('project_title.html');
      return this.project = new Project();
    });
    return describe('project list', function() {
      var fakeAjaxResponse = function fakeAjaxResponse(req) {
        var d;
        expect(req.url).toBe('/api/v3/projects.json?simple=true');
        d = $.Deferred();
        d.resolve(this.projects_data);
        return d.promise();
      };

      beforeEach((function(_this) {
        return function() {
          _this.projects_data = fixture.load('projects.json')[0];
          return spyOn(jQuery, 'ajax').and.callFake(fakeAjaxResponse.bind(_this));
        };
      })(this));
      it('to show on toggle click', (function(_this) {
        return function() {
          $('.js-projects-dropdown-toggle').click();
          return expect($('.header-content').hasClass('open')).toBe(true);
        };
      })(this));
      return it('hide dropdown', function() {
        $(".dropdown-menu-close-icon").click();
        return expect($('.header-content').hasClass('open')).toBe(false);
      });
    });
  });

}).call(this);
