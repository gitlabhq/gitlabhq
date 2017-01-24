/* eslint-disable space-before-function-paren, no-return-assign */
/* global MergeRequest */

/*= require merge_request */

(function() {
  describe('MergeRequest', function() {
    return describe('task lists', function() {
      preloadFixtures('static/merge_requests_show.html.raw');
      beforeEach(function() {
        loadFixtures('static/merge_requests_show.html.raw');
        return this.merge = new MergeRequest();
      });
      it('modifies the Markdown field', function() {
        spyOn(jQuery, 'ajax').and.stub();
        $('input[type=checkbox]').attr('checked', true).trigger('change');
        return expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
      });
      return it('submits an ajax request on tasklist:changed', function() {
        spyOn(jQuery, 'ajax').and.callFake(function(req) {
          expect(req.type).toBe('PATCH');
          expect(req.url).toBe('/foo');
          return expect(req.data.merge_request.description).not.toBe(null);
        });
        return $('.js-task-list-field').trigger('tasklist:changed');
      });
    });
  });
}).call(this);
