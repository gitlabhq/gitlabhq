import Vue from 'vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import { createStore } from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import '~/behaviors/markdown/render_gfm';
import discussionsMockData from '../mock_data/diff_discussions';

describe('DiffDiscussions', () => {
  let vm;
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

  function createComponent(props = {}) {
    const store = createStore();

    vm = createComponentWithStore(Vue.extend(DiffDiscussions), store, {
      discussions: getDiscussionsMockData(),
      ...props,
    }).$mount();
  }

  afterEach(() => {
    vm.$destroy();
  });

  describe('template', () => {
    it('should have notes list', () => {
      createComponent();

      expect(vm.$el.querySelectorAll('.discussion .note.timeline-entry').length).toEqual(5);
    });
  });

  describe('image commenting', () => {
    it('renders collapsible discussion button', () => {
      createComponent({ shouldCollapseDiscussions: true });

      expect(vm.$el.querySelector('.js-diff-notes-toggle')).not.toBe(null);
      expect(vm.$el.querySelector('.js-diff-notes-toggle svg')).not.toBe(null);
      expect(vm.$el.querySelector('.js-diff-notes-toggle').classList).toContain(
        'diff-notes-collapse',
      );
    });

    it('dispatches toggleDiscussion when clicking collapse button', () => {
      createComponent({ shouldCollapseDiscussions: true });

      spyOn(vm.$store, 'dispatch').and.stub();

      vm.$el.querySelector('.js-diff-notes-toggle').click();

      expect(vm.$store.dispatch).toHaveBeenCalledWith('toggleDiscussion', {
        discussionId: vm.discussions[0].id,
      });
    });

    it('renders expand button when discussion is collapsed', done => {
      createComponent({ shouldCollapseDiscussions: true });

      vm.discussions[0].expanded = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.js-diff-notes-toggle').textContent.trim()).toBe('1');
        expect(vm.$el.querySelector('.js-diff-notes-toggle').className).toContain(
          'btn-transparent badge badge-pill',
        );

        done();
      });
    });

    it('hides discussion when collapsed', done => {
      createComponent({ shouldCollapseDiscussions: true });

      vm.discussions[0].expanded = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.note-discussion').style.display).toBe('none');

        done();
      });
    });

    it('renders badge on avatar', () => {
      createComponent({ renderAvatarBadge: true, discussions: [{ ...discussionsMockData }] });

      expect(vm.$el.querySelector('.user-avatar-link .badge-pill')).not.toBe(null);
      expect(vm.$el.querySelector('.user-avatar-link .badge-pill').textContent.trim()).toBe('1');
    });
  });
});
