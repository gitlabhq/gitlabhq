import Vue from 'vue';
import SuggestionDiffComponent from '~/vue_shared/components/markdown/suggestion_diff.vue';

const MOCK_DATA = {
  canApply: true,
  newLines: [
    { content: 'Line 1\n', lineNumber: 1 },
    { content: 'Line 2\n', lineNumber: 2 },
    { content: 'Line 3\n', lineNumber: 3 },
  ],
  fromLine: 1,
  fromContent: 'Old content',
  suggestion: {
    id: 1,
  },
  helpPagePath: 'path_to_docs',
};

describe('Suggestion Diff component', () => {
  let vm;

  beforeEach(done => {
    const Component = Vue.extend(SuggestionDiffComponent);

    vm = new Component({
      propsData: MOCK_DATA,
    }).$mount();

    Vue.nextTick(done);
  });

  describe('init', () => {
    it('renders a suggestion header', () => {
      expect(vm.$el.querySelector('.qa-suggestion-diff-header')).not.toBeNull();
    });

    it('renders a diff table with syntax highlighting', () => {
      expect(vm.$el.querySelector('.md-suggestion-diff.js-syntax-highlight.code')).not.toBeNull();
    });

    it('renders the oldLineNumber', () => {
      const fromLine = vm.$el.querySelector('.qa-old-diff-line-number').innerHTML;

      expect(parseInt(fromLine, 10)).toBe(vm.fromLine);
    });

    it('renders the oldLineContent', () => {
      const fromContent = vm.$el.querySelector('.line_content.old').innerHTML;

      expect(fromContent.includes(vm.fromContent)).toBe(true);
    });

    it('renders the contents of newLines', () => {
      const newLines = vm.$el.querySelectorAll('.line_holder.new');

      newLines.forEach((line, i) => {
        expect(newLines[i].innerHTML.includes(vm.newLines[i].content)).toBe(true);
      });
    });

    it('renders a line number for each line', () => {
      const newLineNumbers = vm.$el.querySelectorAll('.qa-new-diff-line-number');

      newLineNumbers.forEach((line, i) => {
        expect(newLineNumbers[i].innerHTML.includes(vm.newLines[i].lineNumber)).toBe(true);
      });
    });
  });

  describe('applySuggestion', () => {
    it('emits apply event when applySuggestion is called', () => {
      const callback = () => {};
      spyOn(vm, '$emit');
      vm.applySuggestion(callback);

      expect(vm.$emit).toHaveBeenCalledWith('apply', { suggestionId: vm.suggestion.id, callback });
    });
  });
});
