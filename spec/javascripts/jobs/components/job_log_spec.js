import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import component from '~/jobs/components/job_log.vue';
import createStore from '~/jobs/store';
import { resetStore } from '../store/helpers';

describe('Job Log', () => {
  const Component = Vue.extend(component);
  let store;
  let vm;

  const trace =
    '<span>Running with gitlab-runner 12.1.0 (de7731dd)<br/></span><span>  on docker-auto-scale-com d5ae8d25<br/></span><div class="append-right-8" data-timestamp="1565502765" data-section="prepare-executor" role="button"></div><span class="section section-header js-s-prepare-executor">Using Docker executor with image ruby:2.6 ...<br/></span>';

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    resetStore(store);
    vm.$destroy();
  });

  it('renders provided trace', () => {
    vm = mountComponentWithStore(Component, {
      props: {
        trace,
        isComplete: true,
      },
      store,
    });

    expect(vm.$el.querySelector('code').textContent).toContain(
      'Running with gitlab-runner 12.1.0 (de7731dd)',
    );
  });

  describe('while receiving trace', () => {
    it('renders animation', () => {
      vm = mountComponentWithStore(Component, {
        props: {
          trace,
          isComplete: false,
        },
        store,
      });

      expect(vm.$el.querySelector('.js-log-animation')).not.toBeNull();
    });
  });

  describe('when build trace has finishes', () => {
    it('does not render animation', () => {
      vm = mountComponentWithStore(Component, {
        props: {
          trace,
          isComplete: true,
        },
        store,
      });

      expect(vm.$el.querySelector('.js-log-animation')).toBeNull();
    });
  });
});
