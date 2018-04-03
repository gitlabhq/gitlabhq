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
      it('should show a warning message when a custom gitlab-ci.yml file is present', () => {
        vm = mountComponent(Component, {
          newCiYaml: false,
          customCiYaml: true,
          ciConfigPath: 'config/.gitlab-ci.yml',
        });
        const branchMessage = `This branch contains <code>${
          vm.ciConfigPath
        }</code> which is being used as a custom CI config file.`;
        const mergingMessage =
          'Merging will disable the Auto DevOps pipeline configuration for this project.';

        expect(vm.warningMessage).toContain(branchMessage);
        expect(vm.warningMessage).toContain(mergingMessage);
      });

      it('should show a warning message when a gitlab-ci.yml file is present', () => {
        vm = mountComponent(Component, {
          newCiYaml: true,
          customCiYaml: false,
          ciConfigPath: '',
        });
        const branchMessage = 'This branch contains a <code>gitlab-ci.yml</code> file';
        const mergingMessage =
          'Merging will disable the Auto Devops pipeline configuration for this project.';

        expect(vm.warningMessage).toContain(branchMessage);
        expect(vm.warningMessage).toContain(mergingMessage);
      });
    });
  });
});
