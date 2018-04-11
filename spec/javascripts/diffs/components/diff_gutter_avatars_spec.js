import Vue from 'vue';
import DiffGutterAvatarsComponent from '~/diffs/components/diff_gutter_avatars.vue';
import { COUNT_OF_AVATARS_IN_GUTTER } from '~/diffs/constants';
import store from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import discussionsMockData from '../mock_data/diff_discussions';

describe('DiffGutterAvatars', () => {
  let component;
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

  beforeEach(() => {
    component = createComponentWithStore(Vue.extend(DiffGutterAvatarsComponent), store, {
      discussions: getDiscussionsMockData(),
    }).$mount(document.createElement('div'));
  });

  describe('computed', () => {
    describe('discussionsExpanded', () => {
      it('should return true when all discussions are expanded', () => {
        expect(component.discussionsExpanded).toEqual(true);
      });

      it('should return false when all discussions are not expanded', () => {
        component.discussions[0].expanded = false;
        expect(component.discussionsExpanded).toEqual(false);
      });
    });

    describe('allDiscussions', () => {
      it('should return an array of notes', () => {
        expect(component.allDiscussions).toEqual([...component.discussions[0].notes]);
      });
    });

    describe('notesInGutter', () => {
      it('should return a subset of discussions to show in gutter', () => {
        expect(component.notesInGutter.length).toEqual(COUNT_OF_AVATARS_IN_GUTTER);
        expect(component.notesInGutter[0]).toEqual({
          note: component.discussions[0].notes[0].note,
          author: component.discussions[0].notes[0].author,
        });
      });
    });

    describe('moreCount', () => {
      it('should return count of remaining discussions from gutter', () => {
        expect(component.moreCount).toEqual(2);
      });
    });

    describe('moreText', () => {
      it('should return proper text if moreCount > 0', () => {
        expect(component.moreText).toEqual('2 more comments');
      });

      it('should return empty string if there is no discussion', () => {
        component.discussions = [];
        expect(component.moreText).toEqual('');
      });
    });
  });

  describe('methods', () => {
    describe('getTooltipText', () => {
      it('should return original comment if it is shorter than max length', () => {
        const note = component.discussions[0].notes[0];

        expect(component.getTooltipText(note)).toEqual('Administrator: comment 1');
      });

      it('should return truncated version of comment', () => {
        const note = component.discussions[0].notes[1];

        expect(component.getTooltipText(note)).toEqual('Fatih Acet: comment 2 is r...');
      });
    });

    describe('toggleDiscussions', () => {
      it('should toggle all discussions', () => {
        expect(component.discussions[0].expanded).toEqual(true);

        component.$store.dispatch('setInitialNotes', getDiscussionsMockData());
        component.toggleDiscussions();

        expect(component.discussions[0].expanded).toEqual(false);
        component.$store.dispatch('setInitialNotes', []);
      });
    });
  });

  describe('template', () => {
    const buttonSelector = '.js-diff-comment-button';
    const svgSelector = `${buttonSelector} svg`;
    const avatarSelector = '.js-diff-comment-avatar';
    const plusCountSelector = '.js-diff-comment-plus';

    it('should have button to collapse discussions when the discussions expanded', () => {
      expect(component.$el.querySelector(buttonSelector)).toBeDefined();
      expect(component.$el.querySelector(svgSelector)).toBeDefined();
    });

    it('should have user avatars when discussions collapsed', () => {
      component.discussions[0].expanded = false;

      Vue.nextTick(() => {
        expect(component.$el.querySelector(buttonSelector)).toBeNull();
        expect(component.$el.querySelectorAll(avatarSelector).length).toEqual(4);
        expect(component.$el.querySelector(plusCountSelector)).toBeDefined();
        expect(component.$el.querySelector(plusCountSelector).textContent).toEqual('+2');
      });
    });
  });
});
