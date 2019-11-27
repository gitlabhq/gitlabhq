import Vue from 'vue';
import { shallowMount, createLocalVue, createWrapper } from '@vue/test-utils';
import createStore from '~/notes/stores';
import noteActions from '~/notes/components/note_actions.vue';
import { TEST_HOST } from 'spec/test_constants';
import { userDataMock } from '../mock_data';

describe('noteActions', () => {
  let wrapper;
  let store;
  let props;

  const shallowMountNoteActions = propsData => {
    const localVue = createLocalVue();
    return shallowMount(localVue.extend(noteActions), {
      store,
      propsData,
      localVue,
      sync: false,
    });
  };

  beforeEach(() => {
    store = createStore();
    props = {
      accessLevel: 'Maintainer',
      authorId: 26,
      canDelete: true,
      canEdit: true,
      canAwardEmoji: true,
      canReportAsAbuse: true,
      noteId: '539',
      noteUrl: `${TEST_HOST}/group/project/merge_requests/1#note_1`,
      reportAbusePath: `${TEST_HOST}/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26`,
      showReply: false,
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('user is logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);

      wrapper = shallowMountNoteActions(props);
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
      expect(wrapper.find('.js-add-award').attributes('data-position')).toBe('right');
    });

    describe('actions dropdown', () => {
      it('should be possible to edit the comment', () => {
        expect(wrapper.find('.js-note-edit').exists()).toBe(true);
      });

      it('should be possible to report abuse to admin', () => {
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

      it('closes tooltip when dropdown opens', done => {
        wrapper.find('.more-actions-toggle').trigger('click');

        const rootWrapper = createWrapper(wrapper.vm.$root);
        Vue.nextTick()
          .then(() => {
            const emitted = Object.keys(rootWrapper.emitted());

            expect(emitted).toEqual(['bv::hide::tooltip']);
            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', {});
      wrapper = shallowMountNoteActions({
        ...props,
        canDelete: false,
        canEdit: false,
        canAwardEmoji: false,
        canReportAsAbuse: false,
      });
    });

    it('should not render emoji link', () => {
      expect(wrapper.find('.js-add-award').exists()).toBe(false);
    });

    it('should not render actions dropdown', () => {
      expect(wrapper.find('.more-actions').exists()).toBe(false);
    });
  });

  describe('for showReply = true', () => {
    beforeEach(() => {
      wrapper = shallowMountNoteActions({
        ...props,
        showReply: true,
      });
    });

    it('shows a reply button', () => {
      const replyButton = wrapper.find({ ref: 'replyButton' });

      expect(replyButton.exists()).toBe(true);
    });
  });

  describe('for showReply = false', () => {
    beforeEach(() => {
      wrapper = shallowMountNoteActions({
        ...props,
        showReply: false,
      });
    });

    it('does not show a reply button', () => {
      const replyButton = wrapper.find({ ref: 'replyButton' });

      expect(replyButton.exists()).toBe(false);
    });
  });
});
