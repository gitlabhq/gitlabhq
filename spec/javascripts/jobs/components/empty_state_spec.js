import Vue from 'vue';
import component from '~/jobs/components/empty_state.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Empty State', () => {
  const Component = Vue.extend(component);
  let vm;

  const props = {
    illustrationPath: 'illustrations/pending_job_empty.svg',
    illustrationSizeClass: 'svg-430',
    title: 'This job has not started yet',
  };

  const content = 'This job is in pending state and is waiting to be picked by a runner';

  afterEach(() => {
    vm.$destroy();
  });

  describe('renders image and title', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...props,
        content,
      });
    });

    it('renders img with provided path and size', () => {
      expect(vm.$el.querySelector('img').getAttribute('src')).toEqual(props.illustrationPath);
      expect(vm.$el.querySelector('.svg-content').classList).toContain(props.illustrationSizeClass);
    });

    it('renders provided title', () => {
      expect(vm.$el.querySelector('.js-job-empty-state-title').textContent.trim()).toEqual(
        props.title,
      );
    });
  });

  describe('with content', () => {
    it('renders content', () => {
      vm = mountComponent(Component, {
        ...props,
        content,
      });

      expect(vm.$el.querySelector('.js-job-empty-state-content').textContent.trim()).toEqual(
        content,
      );
    });
  });

  describe('without content', () => {
    it('does not render content', () => {
      vm = mountComponent(Component, {
        ...props,
      });
      expect(vm.$el.querySelector('.js-job-empty-state-content')).toBeNull();
    });
  });

  describe('with action', () => {
    it('renders action', () => {
      vm = mountComponent(Component, {
        ...props,
        content,
        action: {
          link: 'runner',
          title: 'Check runner',
          method: 'post',
        },
      });

      expect(vm.$el.querySelector('.js-job-empty-state-action').getAttribute('href')).toEqual(
        'runner',
      );
    });
  });

  describe('without action', () => {
    it('does not render action', () => {
      vm = mountComponent(Component, {
        ...props,
        content,
      });
      expect(vm.$el.querySelector('.js-job-empty-state-action')).toBeNull();
    });
  });
});
