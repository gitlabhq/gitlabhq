import Vue from 'vue';
import component from '~/jobs/components/job_log.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Job Log', () => {
  const Component = Vue.extend(component);
  let vm;

  const trace = 'Running with gitlab-runner 11.1.0 (081978aa)<br>  on docker-auto-scale-com d5ae8d25<br>Using Docker executor with image dev.gitlab.org:5005/gitlab/gitlab-build-images:ruby-2.4.4-golang-1.9-git-2.18-chrome-67.0-node-8.x-yarn-1.2-postgresql-9.6-graphicsmagick-1.3.29 ...<br>';

  afterEach(() => {
    vm.$destroy();
  });

  it('renders provided trace', () => {
    vm = mountComponent(Component, {
      trace,
      isReceivingBuildTrace: true,
    });

    expect(vm.$el.querySelector('code').textContent).toContain('Running with gitlab-runner 11.1.0 (081978aa)');
  });

  describe('while receiving trace', () => {
    it('renders animation', () => {
      vm = mountComponent(Component, {
        trace,
        isReceivingBuildTrace: true,
      });

      expect(vm.$el.querySelector('.js-log-animation')).not.toBeNull();
    });
  });

  describe('when build trace has finishes', () => {
    it('does not render animation', () => {
      vm = mountComponent(Component, {
        trace,
        isReceivingBuildTrace: false,
      });

      expect(vm.$el.querySelector('.js-log-animation')).toBeNull();
    });
  });
});
