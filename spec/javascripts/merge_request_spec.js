/* eslint-disable space-before-function-paren, no-return-assign */
/* global MergeRequest */

require('~/merge_request');

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
        $('input[type=checkbox]').attr('checked', true).trigger('change');
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

    describe('state change', () => {
      preloadFixtures('merge_requests/open-merge-request.html.raw');
      preloadFixtures('merge_requests/closed-merge-request.html.raw');

      beforeEach(function() {
        spyOn(gl.utils, 'visitUrl');
      });

      describe('open merge request', () => {
        beforeEach(() => {
          loadFixtures('merge_requests/open-merge-request.html.raw');

          new MergeRequest();
        });

        describe('on success', () => {
          beforeEach(() => {
            spyOn(jQuery, 'ajax').and.callFake((req) => {
              const d = $.Deferred();
              d.resolve({
                id: 1,
              });
              return d.promise();
            });
          });

          it('change state with no comment', (done) => {
            $('.note-form-actions .btn-close').trigger('click');

            setTimeout(() => {
              expect(gl.utils.visitUrl).toHaveBeenCalled();

              done();
            });
          });

          it('changes state with a comment', (done) => {
            $('.js-note-text').val('testing');
            $('.note-form-actions .btn-close').trigger('click');
            $('.note-form-actions .btn-close').closest('form').trigger('ajax:success');

            setTimeout(() => {
              expect(gl.utils.visitUrl).toHaveBeenCalled();

              done();
            });
          });
        });

        describe('on error', () => {
          beforeEach(() => {
            spyOn(jQuery, 'ajax').and.callFake((req) => {
              const d = $.Deferred();
              d.resolve();
              return d.promise();
            });
          });

          it('shows error message when no comment is left', (done) => {
            $('.note-form-actions .btn-close').trigger('click');

            setTimeout(() => {
              expect($('.flash-alert').length).toBe(1);
              expect(
                $('.flash-alert').text().trim(),
              ).toBe('Unable to update this merge request at this time.');
              expect(gl.utils.visitUrl).not.toHaveBeenCalled();

              done();
            });
          });

          it('changes state with a comment', (done) => {
            $('.js-note-text').val('testing');
            $('.note-form-actions .btn-close').trigger('click');
            $('.note-form-actions .btn-close').closest('form').trigger('ajax:error');

            setTimeout(() => {
              expect($('.flash-alert').length).toBe(1);
              expect(
                $('.flash-alert').text().trim(),
              ).toBe('Unable to update this merge request at this time.');
              expect(gl.utils.visitUrl).not.toHaveBeenCalled();

              done();
            });
          });
        });
      });

      describe('closed merge request', () => {
        beforeEach(() => {
          loadFixtures('merge_requests/closed-merge-request.html.raw');

          new MergeRequest();
        });

        describe('on success', () => {
          beforeEach(() => {
            spyOn(jQuery, 'ajax').and.callFake((req) => {
              const d = $.Deferred();
              d.resolve({
                id: 1,
              });
              return d.promise();
            });
          });

          it('change state with no comment', (done) => {
            $('.note-form-actions .btn-reopen').trigger('click');

            setTimeout(() => {
              expect(gl.utils.visitUrl).toHaveBeenCalled();

              done();
            });
          });

          it('changes state with a comment', (done) => {
            $('.js-note-text').val('testing');
            $('.note-form-actions .btn-reopen').trigger('click');
            $('.note-form-actions .btn-reopen').closest('form').trigger('ajax:success');

            setTimeout(() => {
              expect(gl.utils.visitUrl).toHaveBeenCalled();

              done();
            });
          });
        });

        describe('on error', () => {
          beforeEach(() => {
            spyOn(jQuery, 'ajax').and.callFake((req) => {
              const d = $.Deferred();
              d.resolve();
              return d.promise();
            });
          });

          it('shows error message when no comment is left', (done) => {
            $('.note-form-actions .btn-reopen').trigger('click');

            setTimeout(() => {
              expect($('.flash-alert').length).toBe(1);
              expect(
                $('.flash-alert').text().trim(),
              ).toBe('Unable to update this merge request at this time.');
              expect(gl.utils.visitUrl).not.toHaveBeenCalled();

              done();
            });
          });

          it('changes state with a comment', (done) => {
            $('.js-note-text').val('testing');
            $('.note-form-actions .btn-reopen').trigger('click');
            $('.note-form-actions .btn-reopen').closest('form').trigger('ajax:error');

            setTimeout(() => {
              expect($('.flash-alert').length).toBe(1);
              expect(
                $('.flash-alert').text().trim(),
              ).toBe('Unable to update this merge request at this time.');
              expect(gl.utils.visitUrl).not.toHaveBeenCalled();

              done();
            });
          });
        });
      });
    });
  });
}).call(window);
