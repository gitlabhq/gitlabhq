import Vue from 'vue';
import ImageDiffOverlay from '~/diffs/components/image_diff_overlay.vue';
import { createStore } from '~/mr_notes/stores';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { imageDiffDiscussions } from '../mock_data/diff_discussions';

describe('Diffs image diff overlay component', () => {
  let Component;
  let vm;

  function createComponent(props = {}, extendStore = () => {}) {
    const store = createStore();

    extendStore(store);

    vm = mountComponentWithStore(Component, {
      store,
      props: { discussions: [...imageDiffDiscussions], fileHash: 'ABC', ...props },
    });
  }

  beforeAll(() => {
    Component = Vue.extend(ImageDiffOverlay);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders comment badges', () => {
    createComponent();

    expect(vm.$el.querySelectorAll('.js-image-badge').length).toBe(2);
  });

  it('renders index of discussion in badge', () => {
    createComponent();

    expect(vm.$el.querySelectorAll('.js-image-badge')[0].textContent.trim()).toBe('1');
    expect(vm.$el.querySelectorAll('.js-image-badge')[1].textContent.trim()).toBe('2');
  });

  it('renders icon when showCommentIcon is true', () => {
    createComponent({ showCommentIcon: true });

    expect(vm.$el.querySelector('.js-image-badge svg')).not.toBe(null);
  });

  it('sets badge comment positions', () => {
    createComponent();

    expect(vm.$el.querySelectorAll('.js-image-badge')[0].style.left).toBe('10px');
    expect(vm.$el.querySelectorAll('.js-image-badge')[0].style.top).toBe('10px');

    expect(vm.$el.querySelectorAll('.js-image-badge')[1].style.left).toBe('5px');
    expect(vm.$el.querySelectorAll('.js-image-badge')[1].style.top).toBe('5px');
  });

  it('renders single badge for discussion object', () => {
    createComponent({
      discussions: {
        ...imageDiffDiscussions[0],
      },
    });

    expect(vm.$el.querySelectorAll('.js-image-badge').length).toBe(1);
  });

  it('dispatches openDiffFileCommentForm when clcking overlay', () => {
    createComponent({ canComment: true });

    spyOn(vm.$store, 'dispatch').and.stub();

    vm.$el.querySelector('.js-add-image-diff-note-button').click();

    expect(vm.$store.dispatch).toHaveBeenCalledWith('diffs/openDiffFileCommentForm', {
      fileHash: 'ABC',
      x: 0,
      y: 0,
    });
  });

  describe('toggle discussion', () => {
    it('disables buttons when shouldToggleDiscussion is false', () => {
      createComponent({ shouldToggleDiscussion: false });

      expect(vm.$el.querySelector('.js-image-badge').hasAttribute('disabled')).toBe(true);
    });

    it('dispatches toggleDiscussion when clicking image badge', () => {
      createComponent();

      spyOn(vm.$store, 'dispatch').and.stub();

      vm.$el.querySelector('.js-image-badge').click();

      expect(vm.$store.dispatch).toHaveBeenCalledWith('toggleDiscussion', { discussionId: '1' });
    });
  });

  describe('comment form', () => {
    beforeEach(() => {
      createComponent({}, store => {
        store.state.diffs.commentForms.push({
          fileHash: 'ABC',
          x: 20,
          y: 10,
        });
      });
    });

    it('renders comment form badge', () => {
      expect(vm.$el.querySelector('.comment-indicator')).not.toBe(null);
    });

    it('sets comment form badge position', () => {
      expect(vm.$el.querySelector('.comment-indicator').style.left).toBe('20px');
      expect(vm.$el.querySelector('.comment-indicator').style.top).toBe('10px');
    });
  });
});
