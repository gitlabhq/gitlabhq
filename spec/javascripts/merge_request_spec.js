/* eslint-disable space-before-function-paren, no-return-assign */
/* global MergeRequest */

import '~/merge_request';
import CloseReopenReportToggle from '~/close_reopen_report_toggle';
import IssuablesHelper from '~/helpers/issuables_helper';

(function() {
  describe('MergeRequest', function() {
    describe('task lists', function() {
      preloadFixtures('merge_requests/merge_request_with_task_list.html.raw');
      beforeEach(function() {
        loadFixtures('merge_requests/merge_request_with_task_list.html.raw');
        return this.merge = new MergeRequest();
      });
      it('modifies the Markdown field', function() {
        spyOn(jQuery, 'ajax').and.stub();
        const changeEvent = document.createEvent('HTMLEvents');
        changeEvent.initEvent('change', true, true);
        $('input[type=checkbox]').attr('checked', true)[0].dispatchEvent(changeEvent);
        return expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
      });
      return it('submits an ajax request on tasklist:changed', function() {
        spyOn(jQuery, 'ajax').and.callFake(function(req) {
          expect(req.type).toBe('PATCH');
          expect(req.url).toBe(`${gl.TEST_HOST}/frontend-fixtures/merge-requests-project/merge_requests/1.json`);
          return expect(req.data.merge_request.description).not.toBe(null);
        });
        return $('.js-task-list-field').trigger('tasklist:changed');
      });
    });

    describe('class constructor', () => {
      it('calls .initCloseReopenReport', () => {
        spyOn(IssuablesHelper, 'initCloseReopenReport');

        new MergeRequest(); // eslint-disable-line no-new

        expect(IssuablesHelper.initCloseReopenReport).toHaveBeenCalled();
      });

      it('calls .initDroplab', () => {
        const container = jasmine.createSpyObj('container', ['querySelector']);
        const dropdownTrigger = {};
        const dropdownList = {};
        const button = {};

        spyOn(CloseReopenReportToggle.prototype, 'initDroplab');
        spyOn(document, 'querySelector').and.returnValue(container);
        container.querySelector.and.returnValues(dropdownTrigger, dropdownList, button);

        new MergeRequest(); // eslint-disable-line no-new

        expect(document.querySelector).toHaveBeenCalledWith('.js-issuable-close-dropdown');
        expect(container.querySelector).toHaveBeenCalledWith('.js-issuable-close-toggle');
        expect(container.querySelector).toHaveBeenCalledWith('.js-issuable-close-menu');
        expect(container.querySelector).toHaveBeenCalledWith('.js-issuable-close-button');
        expect(CloseReopenReportToggle.prototype.initDroplab).toHaveBeenCalled();
      });
    });
  });
}).call(window);
