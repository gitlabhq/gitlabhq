import $ from 'jquery';
import Vue from 'vue';
import Autosize from 'autosize';
import store from '~/notes/stores';
import CommentForm from '~/notes/components/comment_form.vue';
import { loggedOutnoteableData, notesDataMock, userDataMock, noteableDataMock } from '../mock_data';
import { keyboardDownEvent } from '../../issue_show/helpers';

describe('issue_comment_form component', () => {
  let vm;
  const Component = Vue.extend(CommentForm);
  let mountComponent;

  beforeEach(() => {
    mountComponent = (noteableType = 'issue') => new Component({
      propsData: {
        noteableType,
      },
      store,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('user is logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);
      store.dispatch('setNoteableData', noteableDataMock);
      store.dispatch('setNotesData', notesDataMock);

      vm = mountComponent();
    });

    it('should render user avatar with link', () => {
      expect(vm.$el.querySelector('.timeline-icon .user-avatar-link').getAttribute('href')).toEqual(userDataMock.path);
    });

    describe('handleSave', () => {
      it('should request to save note when note is entered', () => {
        vm.note = 'hello world';
        spyOn(vm, 'saveNote').and.returnValue(new Promise(() => {}));
        spyOn(vm, 'resizeTextarea');
        spyOn(vm, 'stopPolling');

        vm.handleSave();
        expect(vm.isSubmitting).toEqual(true);
        expect(vm.note).toEqual('');
        expect(vm.saveNote).toHaveBeenCalled();
        expect(vm.stopPolling).toHaveBeenCalled();
        expect(vm.resizeTextarea).toHaveBeenCalled();
      });

      it('should toggle issue state when no note', () => {
        spyOn(vm, 'toggleIssueState');

        vm.handleSave();

        expect(vm.toggleIssueState).toHaveBeenCalled();
      });

      it('should disable action button whilst submitting', (done) => {
        const saveNotePromise = Promise.resolve();
        vm.note = 'hello world';
        spyOn(vm, 'saveNote').and.returnValue(saveNotePromise);
        spyOn(vm, 'stopPolling');

        const actionButton = vm.$el.querySelector('.js-action-button');

        vm.handleSave();

        Vue.nextTick()
          .then(() => expect(actionButton.disabled).toBeTruthy())
          .then(saveNotePromise)
          .then(Vue.nextTick)
          .then(() => expect(actionButton.disabled).toBeFalsy())
          .then(done)
          .catch(done.fail);
      });
    });

    describe('textarea', () => {
      it('should render textarea with placeholder', () => {
        expect(
          vm.$el.querySelector('.js-main-target-form textarea').getAttribute('placeholder'),
        ).toEqual('Write a comment or drag your files here...');
      });

      it('should make textarea disabled while requesting', (done) => {
        const $submitButton = $(vm.$el.querySelector('.js-comment-submit-button'));
        vm.note = 'hello world';
        spyOn(vm, 'stopPolling');
        spyOn(vm, 'saveNote').and.returnValue(new Promise(() => {}));

        vm.$nextTick(() => { // Wait for vm.note change triggered. It should enable $submitButton.
          $submitButton.trigger('click');

          vm.$nextTick(() => { // Wait for vm.isSubmitting triggered. It should disable textarea.
            expect(vm.$el.querySelector('.js-main-target-form textarea').disabled).toBeTruthy();
            done();
          });
        });
      });

      it('should support quick actions', () => {
        expect(
          vm.$el.querySelector('.js-main-target-form textarea').getAttribute('data-supports-quick-actions'),
        ).toEqual('true');
      });

      it('should link to markdown docs', () => {
        const { markdownDocsPath } = notesDataMock;
        expect(vm.$el.querySelector(`a[href="${markdownDocsPath}"]`).textContent.trim()).toEqual('Markdown');
      });

      it('should link to quick actions docs', () => {
        const { quickActionsDocsPath } = notesDataMock;
        expect(vm.$el.querySelector(`a[href="${quickActionsDocsPath}"]`).textContent.trim()).toEqual('quick actions');
      });

      it('should resize textarea after note discarded', (done) => {
        spyOn(Autosize, 'update');
        spyOn(vm, 'discard').and.callThrough();

        vm.note = 'foo';
        vm.discard();

        Vue.nextTick(() => {
          expect(Autosize.update).toHaveBeenCalled();
          done();
        });
      });

      describe('edit mode', () => {
        it('should enter edit mode when arrow up is pressed', () => {
          spyOn(vm, 'editCurrentUserLastNote').and.callThrough();
          vm.$el.querySelector('.js-main-target-form textarea').value = 'Foo';
          vm.$el.querySelector('.js-main-target-form textarea').dispatchEvent(keyboardDownEvent(38, true));

          expect(vm.editCurrentUserLastNote).toHaveBeenCalled();
        });

        it('inits autosave', () => {
          expect(vm.autosave).toBeDefined();
          expect(vm.autosave.key).toEqual(`autosave/Note/Issue/${noteableDataMock.id}`);
        });
      });

      describe('event enter', () => {
        it('should save note when cmd+enter is pressed', () => {
          spyOn(vm, 'handleSave').and.callThrough();
          vm.$el.querySelector('.js-main-target-form textarea').value = 'Foo';
          vm.$el.querySelector('.js-main-target-form textarea').dispatchEvent(keyboardDownEvent(13, true));

          expect(vm.handleSave).toHaveBeenCalled();
        });

        it('should save note when ctrl+enter is pressed', () => {
          spyOn(vm, 'handleSave').and.callThrough();
          vm.$el.querySelector('.js-main-target-form textarea').value = 'Foo';
          vm.$el.querySelector('.js-main-target-form textarea').dispatchEvent(keyboardDownEvent(13, false, true));

          expect(vm.handleSave).toHaveBeenCalled();
        });
      });
    });

    describe('actions', () => {
      it('should be possible to close the issue', () => {
        expect(vm.$el.querySelector('.btn-comment-and-close').textContent.trim()).toEqual('Close issue');
      });

      it('should render comment button as disabled', () => {
        expect(vm.$el.querySelector('.js-comment-submit-button').getAttribute('disabled')).toEqual('disabled');
      });

      it('should enable comment button if it has note', (done) => {
        vm.note = 'Foo';
        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.js-comment-submit-button').getAttribute('disabled')).toEqual(null);
          done();
        });
      });

      it('should update buttons texts when it has note', (done) => {
        vm.note = 'Foo';
        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.btn-comment-and-close').textContent.trim()).toEqual('Comment & close issue');
          expect(vm.$el.querySelector('.js-note-discard')).toBeDefined();
          done();
        });
      });

      it('updates button text with noteable type', (done) => {
        vm.noteableType = 'merge_request';

        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.btn-comment-and-close').textContent.trim()).toEqual('Close merge request');
          done();
        });
      });

      describe('when clicking close/reopen button', () => {
        it('should disable button and show a loading spinner', (done) => {
          const toggleStateButton = vm.$el.querySelector('.js-action-button');

          toggleStateButton.click();
          Vue.nextTick(() => {
            expect(toggleStateButton.disabled).toEqual(true);
            expect(toggleStateButton.querySelector('.js-loading-button-icon')).not.toBeNull();

            done();
          });
        });
      });
    });

    describe('issue is confidential', () => {
      it('shows information warning', (done) => {
        store.dispatch('setNoteableData', Object.assign(noteableDataMock, { confidential: true }));
        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.confidential-issue-warning')).toBeDefined();
          done();
        });
      });
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', null);
      store.dispatch('setNoteableData', loggedOutnoteableData);
      store.dispatch('setNotesData', notesDataMock);

      vm = mountComponent();
    });

    it('should render signed out widget', () => {
      expect(vm.$el.textContent.replace(/\s+/g, ' ').trim()).toEqual('Please register or sign in to reply');
    });

    it('should not render submission form', () => {
      expect(vm.$el.querySelector('textarea')).toEqual(null);
    });
  });
});
