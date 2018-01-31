import Vue from 'vue';
import mergeHelpComponent from '~/vue_merge_request_widget/components/mr_widget_merge_help.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';


const text = `If the ${props.missingBranch} branch exists in your local repository`;

describe('MRWidgetMergeHelp', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(mergeHelpComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

  fdescribe('with missing branch', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        missingBranch: 'this-is-not-the-branch-you-are-looking-for',
      });
    });

    it('renders missing branch information', () => {
      console.log('', vm.$el);

    });
  });

  describe('without missing branch', () => {
    beforeEach(() => {
      vm = mountComponent(Component);
    });
  });
});
