import Vue from 'vue';
import SuggestionDiffHeaderComponent from '~/vue_shared/components/markdown/suggestion_diff_header.vue';

const MOCK_DATA = {
  canApply: true,
  isApplied: false,
  helpPagePath: 'path_to_docs',
};

describe('Suggestion Diff component', () => {
  let vm;

  function createComponent(propsData) {
    const Component = Vue.extend(SuggestionDiffHeaderComponent);

    return new Component({
      propsData,
    }).$mount();
  }

  beforeEach(done => {
    vm = createComponent(MOCK_DATA);
    Vue.nextTick(done);
  });

  describe('init', () => {
    it('renders a suggestion header', () => {
      const header = vm.$el.querySelector('.qa-suggestion-diff-header');

      expect(header).not.toBeNull();
      expect(header.innerHTML.includes('Suggested change')).toBe(true);
    });

    it('renders a help button', () => {
      const helpBtn = vm.$el.querySelector('.js-help-btn');

      expect(helpBtn).not.toBeNull();
    });

    it('renders an apply button', () => {
      const applyBtn = vm.$el.querySelector('.qa-apply-btn');

      expect(applyBtn).not.toBeNull();
      expect(applyBtn.innerHTML.includes('Apply suggestion')).toBe(true);
    });

    it('does not render an apply button if `canApply` is set to false', () => {
      const props = Object.assign(MOCK_DATA, { canApply: false });

      vm = createComponent(props);

      expect(vm.$el.querySelector('.qa-apply-btn')).toBeNull();
    });
  });

  describe('applySuggestion', () => {
    it('emits when the apply button is clicked', () => {
      const props = Object.assign(MOCK_DATA, { canApply: true });

      vm = createComponent(props);
      spyOn(vm, '$emit');
      vm.applySuggestion();

      expect(vm.$emit).toHaveBeenCalled();
    });

    it('does not emit when the canApply is set to false', () => {
      spyOn(vm, '$emit');
      vm.canApply = false;
      vm.applySuggestion();

      expect(vm.$emit).not.toHaveBeenCalled();
    });
  });
});
