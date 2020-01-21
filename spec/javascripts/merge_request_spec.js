import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MergeRequest from '~/merge_request';
import CloseReopenReportToggle from '~/close_reopen_report_toggle';
import IssuablesHelper from '~/helpers/issuables_helper';

describe('MergeRequest', function() {
  describe('task lists', function() {
    let mock;

    preloadFixtures('merge_requests/merge_request_with_task_list.html');
    beforeEach(function() {
      loadFixtures('merge_requests/merge_request_with_task_list.html');

      spyOn(axios, 'patch').and.callThrough();
      mock = new MockAdapter(axios);

      mock
        .onPatch(`${gl.TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`)
        .reply(200, {});

      this.merge = new MergeRequest();
      return this.merge;
    });

    afterEach(() => {
      mock.restore();
    });

    it('modifies the Markdown field', done => {
      spyOn($, 'ajax').and.stub();
      const changeEvent = document.createEvent('HTMLEvents');
      changeEvent.initEvent('change', true, true);
      $('input[type=checkbox]')
        .first()
        .attr('checked', true)[0]
        .dispatchEvent(changeEvent);
      setTimeout(() => {
        expect($('.js-task-list-field').val()).toBe(
          '- [x] Task List Item\n- [ ]   \n- [ ] Task List Item 2\n',
        );
        done();
      });
    });

    it('ensure that task with only spaces does not get checked incorrectly', done => {
      // fixed in 'deckar01-task_list', '2.2.1' gem
      spyOn($, 'ajax').and.stub();
      const changeEvent = document.createEvent('HTMLEvents');
      changeEvent.initEvent('change', true, true);
      $('input[type=checkbox]')
        .last()
        .attr('checked', true)[0]
        .dispatchEvent(changeEvent);
      setTimeout(() => {
        expect($('.js-task-list-field').val()).toBe(
          '- [ ] Task List Item\n- [ ]   \n- [x] Task List Item 2\n',
        );
        done();
      });
    });

    describe('tasklist', () => {
      const lineNumber = 8;
      const lineSource = '- [ ] item 8';
      const index = 3;
      const checked = true;

      it('submits an ajax request on tasklist:changed', done => {
        $('.js-task-list-field').trigger({
          type: 'tasklist:changed',
          detail: { lineNumber, lineSource, index, checked },
        });

        setTimeout(() => {
          expect(axios.patch).toHaveBeenCalledWith(
            `${gl.TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`,
            {
              merge_request: {
                description: '- [ ] Task List Item\n- [ ]   \n- [ ] Task List Item 2\n',
                lock_version: 0,
                update_task: { line_number: lineNumber, line_source: lineSource, index, checked },
              },
            },
          );

          done();
        });
      });

      // https://gitlab.com/gitlab-org/gitlab/issues/34861
      // eslint-disable-next-line jasmine/no-disabled-tests
      xit('shows an error notification when tasklist update failed', done => {
        mock
          .onPatch(
            `${gl.TEST_HOST}/frontend-fixtures/merge-requests-project/-/merge_requests/1.json`,
          )
          .reply(409, {});

        $('.js-task-list-field').trigger({
          type: 'tasklist:changed',
          detail: { lineNumber, lineSource, index, checked },
        });

        setTimeout(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            'Someone edited this merge request at the same time you did. Please refresh the page to see changes.',
          );

          done();
        });
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
        loadFixtures('merge_requests/merge_request_with_task_list.html');
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
        loadFixtures('merge_requests/merge_request_of_current_user.html');
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
