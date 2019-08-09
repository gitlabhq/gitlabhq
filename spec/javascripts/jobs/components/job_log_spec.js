import Vue from 'vue';
import component from '~/jobs/components/job_log.vue';
import createStore from '~/jobs/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../store/helpers';
import { logWithCollapsibleSections } from '../mock_data';

describe('Job Log', () => {
  const Component = Vue.extend(component);
  let store;
  let vm;

  const trace =
    'Running with gitlab-runner 11.1.0 (081978aa)<br>  on docker-auto-scale-com d5ae8d25<br>Using Docker executor with image dev.gitlab.org:5005/gitlab/gitlab-build-images:ruby-2.4.4-golang-1.9-git-2.18-chrome-67.0-node-8.x-yarn-1.2-postgresql-9.6-graphicsmagick-1.3.29 ...<br>';

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
      'Running with gitlab-runner 11.1.0 (081978aa)',
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

  describe('Collapsible sections', () => {
    beforeEach(() => {
      vm = mountComponentWithStore(Component, {
        props: {
          trace: logWithCollapsibleSections.html,
          isComplete: true,
        },
        store,
      });
    });

    it('renders open arrow', () => {
      expect(vm.$el.querySelector('.fa-caret-down')).not.toBeNull();
    });

    it('toggles hidden class to the sibilings rows when arrow is clicked', done => {
      vm.$nextTick()
        .then(() => {
          const { section } = vm.$el.querySelector('.js-section-start').dataset;
          vm.$el.querySelector('.js-section-start').click();

          vm.$el.querySelectorAll(`.js-s-${section}:not(.js-section-header)`).forEach(el => {
            expect(el.classList.contains('hidden')).toEqual(true);
          });

          vm.$el.querySelector('.js-section-start').click();

          vm.$el.querySelectorAll(`.js-s-${section}:not(.js-section-header)`).forEach(el => {
            expect(el.classList.contains('hidden')).toEqual(false);
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('toggles hidden class to the sibilings rows when header section is clicked', done => {
      vm.$nextTick()
        .then(() => {
          const { section } = vm.$el.querySelector('.js-section-header').dataset;
          vm.$el.querySelector('.js-section-header').click();

          vm.$el.querySelectorAll(`.js-s-${section}:not(.js-section-header)`).forEach(el => {
            expect(el.classList.contains('hidden')).toEqual(true);
          });

          vm.$el.querySelector('.js-section-header').click();

          vm.$el.querySelectorAll(`.js-s-${section}:not(.js-section-header)`).forEach(el => {
            expect(el.classList.contains('hidden')).toEqual(false);
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
