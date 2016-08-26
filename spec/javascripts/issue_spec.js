/* eslint-disable */

/*= require lib/utils/text_utility */
/*= require issue */

(function() {
  var INVALID_URL = 'http://goesnowhere.nothing/whereami';
  var $boxClosed, $boxOpen, $btnClose, $btnReopen;

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
    return describe('task lists', function() {
      fixture.preload('issues_show.html');
      beforeEach(function() {
        fixture.load('issues_show.html');
        return this.issue = new Issue();
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
          return expect(req.data.issue.description).not.toBe(null);
        });
        return $('.js-task-list-field').trigger('tasklist:changed');
      });
    });
  });

  describe('close issue', function() {
    fixture.preload('issues_show.html');

    beforeEach(function() {
      fixture.load('issues_show.html');
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
    });
  });

  describe('reopen issue', function() {
    fixture.preload('issues_show.html');

    beforeEach(function() {
      fixture.load('issues_show.html');
      findElements();
      this.issue = new Issue();

      // TODO: fixture is an open issue, we should replace it by a closed issue
      expectIssueState(true);
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
    });
  });

}).call(this);
