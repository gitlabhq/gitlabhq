import Vue from 'vue';
import autosize from 'vendor/autosize';
import store from '~/notes/stores';
import issueCommentForm from '~/notes/components/issue_comment_form.vue';
import { loggedOutIssueData, notesDataMock, userDataMock, issueDataMock } from '../mock_data';
import { keyboardDownEvent } from '../../issue_show/helpers';

describe('issue_comment_form component', () => {
  let vm;
  const Component = Vue.extend(issueCommentForm);
  let mountComponent;

  beforeEach(() => {
    mountComponent = () => new Component({
      store,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('user is logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);
      store.dispatch('setIssueData', issueDataMock);
      store.dispatch('setNotesData', notesDataMock);

      vm = mountComponent();
    });

    it('should render user avatar with link', () => {
      expect(vm.$el.querySelector('.timeline-icon .user-avatar-link').getAttribute('href')).toEqual(userDataMock.path);
    });

    describe('textarea', () => {
      it('should render textarea with placeholder', () => {
        expect(
          vm.$el.querySelector('.js-main-target-form textarea').getAttribute('placeholder'),
        ).toEqual('Write a comment or drag your files here...');
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
        spyOn(autosize, 'update');
        spyOn(vm, 'discard').and.callThrough();

        vm.note = 'foo';
        vm.discard();

        Vue.nextTick(() => {
          expect(autosize.update).toHaveBeenCalled();
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
      });

      describe('event enter', () => {
        it('should save note when cmd/ctrl+enter is pressed', () => {
          spyOn(vm, 'handleSave').and.callThrough();
          vm.$el.querySelector('.js-main-target-form textarea').value = 'Foo';
          vm.$el.querySelector('.js-main-target-form textarea').dispatchEvent(keyboardDownEvent(13, true));

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
    });

    describe('issue is confidential', () => {
      it('shows information warning', (done) => {
        store.dispatch('setIssueData', Object.assign(issueDataMock, { confidential: true }));
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
      store.dispatch('setIssueData', loggedOutIssueData);
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
