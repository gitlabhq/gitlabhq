import Vue from 'vue';
import mergeHelpComponent from '~/vue_merge_request_widget/components/mr_widget_merge_help';

const props = {
  missingBranch: 'this-is-not-the-branch-you-are-looking-for',
};
const text = `If the ${props.missingBranch} branch exists in your local repository`;

const createComponent = () => {
  const Component = Vue.extend(mergeHelpComponent);
  return new Component({
    el: document.createElement('div'),
    propsData: props,
  });
};

describe('MRWidgetMergeHelp', () => {
  describe('props', () => {
    it('should have props', () => {
      const { missingBranch } = mergeHelpComponent.props;
      const MissingBranchTypeClass = missingBranch.type;

      expect(new MissingBranchTypeClass() instanceof String).toBeTruthy();
      expect(missingBranch.required).toBeFalsy();
      expect(missingBranch.default).toEqual('');
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent();
      el = vm.$el;
    });

    it('should have the correct elements', () => {
      expect(el.classList.contains('mr-widget-help')).toBeTruthy();
      expect(el.textContent).toContain(text);
    });

    it('should not show missing branch name if missingBranch props is not provided', (done) => {
      vm.missingBranch = null;
      Vue.nextTick(() => {
        expect(el.textContent).not.toContain(text);
        done();
      });
    });
  });
});
