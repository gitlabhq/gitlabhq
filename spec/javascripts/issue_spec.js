/* eslint-disable space-before-function-paren, no-var, one-var, one-var-declaration-per-line, no-use-before-define, comma-dangle, max-len */
/* global Issue */

require('~/lib/utils/text_utility');
require('~/issue');

(function() {
  var INVALID_URL = 'http://goesnowhere.nothing/whereami';
  var $boxClosed, $boxOpen, $btnClose, $btnReopen;

  preloadFixtures('issues/closed-issue.html.raw');
  preloadFixtures('issues/issue-with-task-list.html.raw');
  preloadFixtures('issues/open-issue.html.raw');

  function expectErrorMessage() {
    var $flashMessage = $('div.flash-alert');
    expect($flashMessage).toExist();
    expect($flashMessage).toBeVisible();
    expect($flashMessage).toHaveText('Unable to update this issue at this time.');
  }

  function expectIssueState(isIssueOpen) {
    expectVisibility($boxClosed, !isIssueOpen);
    expectVisibility($boxOpen, isIssueOpen);

    expectVisibility($btnClose, isIssueOpen);
    expectVisibility($btnReopen, !isIssueOpen);
  }

  function expectPendingRequest(req, $triggeredButton) {
    expect(req.type).toBe('PUT');
    expect(req.url).toBe($triggeredButton.attr('href'));
    expect($triggeredButton).toHaveProp('disabled', true);
  }

  function expectVisibility($element, shouldBeVisible) {
    if (shouldBeVisible) {
      expect($element).not.toHaveClass('hidden');
    } else {
      expect($element).toHaveClass('hidden');
    }
  }

  function findElements() {
    $boxClosed = $('div.status-box-closed');
    expect($boxClosed).toExist();
    expect($boxClosed).toHaveText('Closed');

    $boxOpen = $('div.status-box-open');
    expect($boxOpen).toExist();
    expect($boxOpen).toHaveText('Open');

    $btnClose = $('.btn-close.btn-grouped');
    expect($btnClose).toExist();
    expect($btnClose).toHaveText('Close issue');

    $btnReopen = $('.btn-reopen.btn-grouped');
    expect($btnReopen).toExist();
    expect($btnReopen).toHaveText('Reopen issue');
  }

  describe('Issue', function() {
    describe('task lists', function() {
      beforeEach(function() {
        loadFixtures('issues/issue-with-task-list.html.raw');
        this.issue = new Issue();
      });

      it('modifies the Markdown field', function() {
        spyOn(jQuery, 'ajax').and.stub();
        $('input[type=checkbox]').attr('checked', true).trigger('change');
        expect($('.js-task-list-field').val()).toBe('- [x] Task List Item');
      });

      it('submits an ajax request on tasklist:changed', function() {
        spyOn(jQuery, 'ajax').and.callFake(function(req) {
          expect(req.type).toBe('PATCH');
          expect(req.url).toBe(gl.TEST_HOST + '/frontend-fixtures/issues-project/issues/1.json'); // eslint-disable-line prefer-template
          expect(req.data.issue.description).not.toBe(null);
        });

        $('.js-task-list-field').trigger('tasklist:changed');
      });
    });
  });

  describe('close issue', function() {
    beforeEach(function() {
      loadFixtures('issues/open-issue.html.raw');
      findElements();
      this.issue = new Issue();

      expectIssueState(true);
    });

    it('closes an issue', function() {
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expectPendingRequest(req, $btnClose);
        req.success({
          id: 34
        });
      });

      $btnClose.trigger('click');

      expectIssueState(false);
      expect($btnClose).toHaveProp('disabled', false);
      expect($('.issue_counter')).toHaveText(0);
    });

    it('fails to close an issue with success:false', function() {
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expectPendingRequest(req, $btnClose);
        req.success({
          saved: false
        });
      });

      $btnClose.attr('href', INVALID_URL);
      $btnClose.trigger('click');

      expectIssueState(true);
      expect($btnClose).toHaveProp('disabled', false);
      expectErrorMessage();
      expect($('.issue_counter')).toHaveText(1);
    });

    it('fails to closes an issue with HTTP error', function() {
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expectPendingRequest(req, $btnClose);
        req.error();
      });

      $btnClose.attr('href', INVALID_URL);
      $btnClose.trigger('click');

      expectIssueState(true);
      expect($btnClose).toHaveProp('disabled', true);
      expectErrorMessage();
      expect($('.issue_counter')).toHaveText(1);
    });
  });

  describe('reopen issue', function() {
    beforeEach(function() {
      loadFixtures('issues/closed-issue.html.raw');
      findElements();
      this.issue = new Issue();

      expectIssueState(false);
    });

    it('reopens an issue', function() {
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expectPendingRequest(req, $btnReopen);
        req.success({
          id: 34
        });
      });

      $btnReopen.trigger('click');

      expectIssueState(true);
      expect($btnReopen).toHaveProp('disabled', false);
      expect($('.issue_counter')).toHaveText(1);
    });
  });
}).call(window);
