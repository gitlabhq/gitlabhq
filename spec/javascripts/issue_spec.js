/* eslint-disable */

/*= require lib/utils/text_utility */
/*= require issue */

(function() {
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

  describe('reopen/close issue', function() {
    fixture.preload('issues_show.html');
    beforeEach(function() {
      fixture.load('issues_show.html');
      return this.issue = new Issue();
    });
    it('closes an issue', function() {
      var $btnClose, $btnReopen;
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expect(req.type).toBe('PUT');
        expect(req.url).toBe('http://gitlab.com/issues/6/close');
        return req.success({
          id: 34
        });
      });
      $btnClose = $('a.btn-close');
      $btnReopen = $('a.btn-reopen');
      expect($btnReopen).toBeHidden();
      expect($btnClose.text()).toBe('Close');
      expect(typeof $btnClose.prop('disabled')).toBe('undefined');
      $btnClose.trigger('click');
      expect($btnReopen).toBeVisible();
      expect($btnClose).toBeHidden();
      expect($('div.status-box-closed')).toBeVisible();
      return expect($('div.status-box-open')).toBeHidden();
    });
    it('fails to close an issue with success:false', function() {
      var $btnClose, $btnReopen;
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expect(req.type).toBe('PUT');
        expect(req.url).toBe('http://goesnowhere.nothing/whereami');
        return req.success({
          saved: false
        });
      });
      $btnClose = $('a.btn-close');
      $btnReopen = $('a.btn-reopen');
      $btnClose.attr('href', 'http://goesnowhere.nothing/whereami');
      expect($btnReopen).toBeHidden();
      expect($btnClose.text()).toBe('Close');
      expect(typeof $btnClose.prop('disabled')).toBe('undefined');
      $btnClose.trigger('click');
      expect($btnReopen).toBeHidden();
      expect($btnClose).toBeVisible();
      expect($('div.status-box-closed')).toBeHidden();
      expect($('div.status-box-open')).toBeVisible();
      expect($('div.flash-alert')).toBeVisible();
      return expect($('div.flash-alert').text()).toBe('Unable to update this issue at this time.');
    });
    it('fails to closes an issue with HTTP error', function() {
      var $btnClose, $btnReopen;
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expect(req.type).toBe('PUT');
        expect(req.url).toBe('http://goesnowhere.nothing/whereami');
        return req.error();
      });
      $btnClose = $('a.btn-close');
      $btnReopen = $('a.btn-reopen');
      $btnClose.attr('href', 'http://goesnowhere.nothing/whereami');
      expect($btnReopen).toBeHidden();
      expect($btnClose.text()).toBe('Close');
      expect(typeof $btnClose.prop('disabled')).toBe('undefined');
      $btnClose.trigger('click');
      expect($btnReopen).toBeHidden();
      expect($btnClose).toBeVisible();
      expect($('div.status-box-closed')).toBeHidden();
      expect($('div.status-box-open')).toBeVisible();
      expect($('div.flash-alert')).toBeVisible();
      return expect($('div.flash-alert').text()).toBe('Unable to update this issue at this time.');
    });
    return it('reopens an issue', function() {
      var $btnClose, $btnReopen;
      spyOn(jQuery, 'ajax').and.callFake(function(req) {
        expect(req.type).toBe('PUT');
        expect(req.url).toBe('http://gitlab.com/issues/6/reopen');
        return req.success({
          id: 34
        });
      });
      $btnClose = $('a.btn-close');
      $btnReopen = $('a.btn-reopen');
      expect($btnReopen.text()).toBe('Reopen');
      $btnReopen.trigger('click');
      expect($btnReopen).toBeHidden();
      expect($btnClose).toBeVisible();
      expect($('div.status-box-open')).toBeVisible();
      return expect($('div.status-box-closed')).toBeHidden();
    });
  });

}).call(this);
