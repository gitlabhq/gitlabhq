import Vue from 'vue';
import autodevopsComponent from '~/vue_merge_request_widget/components/mr_widget_autodevops.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetAutoDevOps', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(autodevopsComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Computed', () => {
    describe('autoDevopsMsg', () => {
      it('should contain a warning message when the gitlab-ci.yml is present', () => {
        vm = mountComponent(Component, {});
        const componentText = vm.$el.querySelector('.media-body').textContent;
        const branchMessage = 'This branch contains a gitlab-ci.yml file.';
        const mergingMessage =
          'Merging will disable the Auto Devops pipeline configuration for this project';

        expect(componentText).toContain(branchMessage);
        expect(componentText).toContain(mergingMessage);
      });
    });
  });
});
