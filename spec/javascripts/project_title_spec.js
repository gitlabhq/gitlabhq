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
  describe('Project Title', function() {
    preloadFixtures('static/project_title.html.raw');
    beforeEach(function() {
      loadFixtures('static/project_title.html.raw');

      window.gon = {};
      window.gon.api_version = 'v3';

      return this.project = new Project();
    });

    describe('project list', function() {
      var fakeAjaxResponse = function fakeAjaxResponse(req) {
        var d;
        expect(req.url).toBe('/api/v3/projects.json?simple=true');
        expect(req.data).toEqual({ search: '', order_by: 'last_activity_at', per_page: 20 });
        d = $.Deferred();
        d.resolve(this.projects_data);
        return d.promise();
      };

      beforeEach((function(_this) {
        return function() {
          _this.projects_data = getJSONFixture('projects.json');
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

    afterEach(() => {
      window.gon = {};
    });
  });

}).call(this);
