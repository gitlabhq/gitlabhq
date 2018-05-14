/* eslint-disable space-before-function-paren, no-return-assign */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MergeRequest from '~/merge_request';
import CloseReopenReportToggle from '~/close_reopen_report_toggle';
import IssuablesHelper from '~/helpers/issuables_helper';

(function() {
  describe('MergeRequest', function() {
    describe('task lists', function() {
      let mock;

      preloadFixtures('merge_requests/merge_request_with_task_list.html.raw');
      beforeEach(function() {
        loadFixtures('merge_requests/merge_request_with_task_list.html.raw');

        spyOn(axios, 'patch').and.callThrough();
        mock = new MockAdapter(axios);

        mock.onPatch(`${gl.TEST_HOST}/frontend-fixtures/merge-requests-project/merge_requests/1.json`).reply(200, {});

        return this.merge = new MergeRequest();
      });

      afterEach(() => {
        mock.restore();
      });

      it('modifies the Markdown field', function() {
        spyOn($, 'ajax').and.stub();
        const changeEvent = document.createEvent('HTMLEvents');
        changeEvent.initEvent('change', true, true);
        $('input[type=checkbox]').attr('checked', true)[0].dispatchEvent(changeEvent);
        return expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
      });

      it('submits an ajax request on tasklist:changed', (done) => {
        $('.js-task-list-field').trigger('tasklist:changed');

        setTimeout(() => {
          expect(axios.patch).toHaveBeenCalledWith(`${gl.TEST_HOST}/frontend-fixtures/merge-requests-project/merge_requests/1.json`, {
            merge_request: { description: '- [ ] Task List Item' },
          });
          done();
        });
      });
    });

    describe('class constructor', () => {
      beforeEach(() => {
        spyOn($, 'ajax').and.stub();
      });

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

    describe('hideCloseButton', () => {
      describe('merge request of another user', () => {
        beforeEach(() => {
          loadFixtures('merge_requests/merge_request_with_task_list.html.raw');
          this.el = document.querySelector('.js-issuable-actions');
          new MergeRequest(); // eslint-disable-line no-new
          MergeRequest.hideCloseButton();
        });

        it('hides the dropdown close item and selects the next item', () => {
          const closeItem = this.el.querySelector('li.close-item');
          const smallCloseItem = this.el.querySelector('.js-close-item');
          const reportItem = this.el.querySelector('li.report-item');

          expect(closeItem).toHaveClass('hidden');
          expect(smallCloseItem).toHaveClass('hidden');
          expect(reportItem).toHaveClass('droplab-item-selected');
          expect(reportItem).not.toHaveClass('hidden');
        });
      });

      describe('merge request of current_user', () => {
        beforeEach(() => {
          loadFixtures('merge_requests/merge_request_of_current_user.html.raw');
          this.el = document.querySelector('.js-issuable-actions');
          MergeRequest.hideCloseButton();
        });

        it('hides the close button', () => {
          const closeButton = this.el.querySelector('.btn-close');
          const smallCloseItem = this.el.querySelector('.js-close-item');

          expect(closeButton).toHaveClass('hidden');
          expect(smallCloseItem).toHaveClass('hidden');
        });
      });
    });
  });
}).call(window);
