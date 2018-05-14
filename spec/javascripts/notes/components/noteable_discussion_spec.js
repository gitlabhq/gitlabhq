import Vue from 'vue';
import store from '~/notes/stores';
import issueDiscussion from '~/notes/components/noteable_discussion.vue';
import { noteableDataMock, discussionMock, notesDataMock } from '../mock_data';

describe('issue_discussion component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(issueDiscussion);

    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
      propsData: {
        note: discussionMock,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render user avatar', () => {
    expect(vm.$el.querySelector('.user-avatar-link')).not.toBeNull();
  });

  it('should render discussion header', () => {
    expect(vm.$el.querySelector('.discussion-header')).not.toBeNull();
    expect(vm.$el.querySelector('.notes').children.length).toEqual(discussionMock.notes.length);
  });

  describe('actions', () => {
    it('should render reply button', () => {
      expect(vm.$el.querySelector('.js-vue-discussion-reply').textContent.trim()).toEqual(
        'Reply...',
      );
    });

    it('should toggle reply form', done => {
      vm.$el.querySelector('.js-vue-discussion-reply').click();
      Vue.nextTick(() => {
        expect(vm.$refs.noteForm).not.toBeNull();
        expect(vm.isReplying).toEqual(true);
        done();
      });
    });

    it('does not render jump to discussion button', () => {
      expect(
        vm.$el.querySelector('*[data-original-title="Jump to next unresolved discussion"]'),
      ).toBeNull();
    });
  });
});
