import { mount, createLocalVue } from '@vue/test-utils';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { createStore } from '~/mr_notes/stores';
import '~/behaviors/markdown/render_gfm';
import discussionsMockData from '../mock_data/diff_discussions';

const localVue = createLocalVue();

describe('DiffDiscussions', () => {
  let store;
  let wrapper;
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

  const createComponent = props => {
    store = createStore();
    wrapper = mount(localVue.extend(DiffDiscussions), {
      store,
      propsData: {
        discussions: getDiscussionsMockData(),
        ...props,
      },
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('should have notes list', () => {
      createComponent();

      expect(wrapper.find(NoteableDiscussion).exists()).toBe(true);
      expect(wrapper.find(DiscussionNotes).exists()).toBe(true);
      expect(wrapper.find(DiscussionNotes).findAll(TimelineEntryItem).length).toBe(
        discussionsMockData.notes.length,
      );
    });
  });

  describe('image commenting', () => {
    const findDiffNotesToggle = () => wrapper.find('.js-diff-notes-toggle');

    it('renders collapsible discussion button', () => {
      createComponent({ shouldCollapseDiscussions: true });
      const diffNotesToggle = findDiffNotesToggle();

      expect(diffNotesToggle.exists()).toBe(true);
      expect(diffNotesToggle.find(Icon).exists()).toBe(true);
      expect(diffNotesToggle.classes('diff-notes-collapse')).toBe(true);
    });

    it('dispatches toggleDiscussion when clicking collapse button', () => {
      createComponent({ shouldCollapseDiscussions: true });
      spyOn(wrapper.vm.$store, 'dispatch').and.stub();
      const diffNotesToggle = findDiffNotesToggle();
      diffNotesToggle.trigger('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('toggleDiscussion', {
        discussionId: discussionsMockData.id,
      });
    });

    it('renders expand button when discussion is collapsed', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expanded = false;
      createComponent({ discussions, shouldCollapseDiscussions: true });
      const diffNotesToggle = findDiffNotesToggle();

      expect(diffNotesToggle.text().trim()).toBe('1');
      expect(diffNotesToggle.classes()).toEqual(
        jasmine.arrayContaining(['btn-transparent', 'badge', 'badge-pill']),
      );
    });

    it('hides discussion when collapsed', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expanded = false;
      createComponent({ discussions, shouldCollapseDiscussions: true });

      expect(wrapper.find(NoteableDiscussion).isVisible()).toBe(false);
    });

    it('renders badge on avatar', () => {
      createComponent({ renderAvatarBadge: true });
      const noteableDiscussion = wrapper.find(NoteableDiscussion);

      expect(noteableDiscussion.find('.badge-pill').exists()).toBe(true);
      expect(
        noteableDiscussion
          .find('.badge-pill')
          .text()
          .trim(),
      ).toBe('1');
    });
  });
});
