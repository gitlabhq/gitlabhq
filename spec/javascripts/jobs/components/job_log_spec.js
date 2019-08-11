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
    '<span>Running with gitlab-runner 12.1.0 (de7731dd)<br/></span><span>  on docker-auto-scale-com d5ae8d25<br/></span><div class="js-section-start fa fa-caret-down append-right-8 cursor-pointer" data-timestamp="1565502765" data-section="prepare-executor" role="button"></div><span class="section js-section-header section-header js-s-prepare-executor">Using Docker executor with image ruby:2.6 ...<br/></span>';

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
