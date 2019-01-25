import Vue from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/notes/stores';
import noteActions from '~/notes/components/note_actions.vue';
import { userDataMock } from '../mock_data';

describe('noteActions', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('user is logged in', () => {
    let props;

    beforeEach(() => {
      props = {
        accessLevel: 'Maintainer',
        authorId: 26,
        canDelete: true,
        canEdit: true,
        canAwardEmoji: true,
        canReportAsAbuse: true,
        noteId: '539',
        noteUrl: 'https://localhost:3000/group/project/merge_requests/1#note_1',
        reportAbusePath:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26',
      };

      store.dispatch('setUserData', userDataMock);

      const localVue = createLocalVue();
      wrapper = shallowMount(noteActions, {
        store,
        propsData: props,
        localVue,
        sync: false,
      });
    });

    it('should render access level badge', () => {
      expect(
        wrapper
          .find('.note-role')
          .text()
          .trim(),
      ).toEqual(props.accessLevel);
    });

    it('should render emoji link', () => {
      expect(wrapper.find('.js-add-award').exists()).toBe(true);
    });

    describe('actions dropdown', () => {
      it('should be possible to edit the comment', () => {
        expect(wrapper.find('.js-note-edit').exists()).toBe(true);
      });

      it('should be possible to report abuse to GitLab', () => {
        expect(wrapper.find(`a[href="${props.reportAbusePath}"]`).exists()).toBe(true);
      });

      it('should be possible to copy link to a note', () => {
        expect(wrapper.find('.js-btn-copy-note-link').exists()).toBe(true);
      });

      it('should not show copy link action when `noteUrl` prop is empty', done => {
        wrapper.setProps({
          ...props,
          noteUrl: '',
        });

        Vue.nextTick()
          .then(() => {
            expect(wrapper.find('.js-btn-copy-note-link').exists()).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });

      it('should be possible to delete comment', () => {
        expect(wrapper.find('.js-note-delete').exists()).toBe(true);
      });
    });
  });

  describe('user is not logged in', () => {
    let props;

    beforeEach(() => {
      store.dispatch('setUserData', {});
      props = {
        accessLevel: 'Maintainer',
        authorId: 26,
        canDelete: false,
        canEdit: false,
        canAwardEmoji: false,
        canReportAsAbuse: false,
        noteId: '539',
        noteUrl: 'https://localhost:3000/group/project/merge_requests/1#note_1',
        reportAbusePath:
          '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26',
      };
      const localVue = createLocalVue();
      wrapper = shallowMount(noteActions, {
        store,
        propsData: props,
        localVue,
        sync: false,
      });
    });

    it('should not render emoji link', () => {
      expect(wrapper.find('.js-add-award').exists()).toBe(false);
    });

    it('should not render actions dropdown', () => {
      expect(wrapper.find('.more-actions').exists()).toBe(false);
    });
  });
});
