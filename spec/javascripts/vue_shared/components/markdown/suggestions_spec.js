import Vue from 'vue';
import SuggestionsComponent from '~/vue_shared/components/markdown/suggestions.vue';

const MOCK_DATA = {
  fromLine: 1,
  fromContent: 'Old content',
  suggestions: [],
  noteHtml: `
    <div class="suggestion">
      <div class="line">Suggestion 1</div>
    </div>    
    
    <div class="suggestion">
      <div class="line">Suggestion 2</div>
    </div>
  `,
  isApplied: false,
  helpPagePath: 'path_to_docs',
};

const generateLine = content => {
  const line = document.createElement('div');
  line.className = 'line';
  line.innerHTML = content;

  return line;
};

const generateMockLines = () => {
  const line1 = generateLine('Line 1');
  const line2 = generateLine('Line 2');
  const line3 = generateLine('- Line 3');
  const container = document.createElement('div');

  container.appendChild(line1);
  container.appendChild(line2);
  container.appendChild(line3);

  return container;
};

describe('Suggestion component', () => {
  let vm;
  let extractedLines;
  let diffTable;

  beforeEach(done => {
    const Component = Vue.extend(SuggestionsComponent);

    vm = new Component({
      propsData: MOCK_DATA,
    }).$mount();

    extractedLines = vm.extractNewLines(generateMockLines());
    diffTable = vm.generateDiff(extractedLines).$mount().$el;

    spyOn(vm, 'renderSuggestions');
    vm.renderSuggestions();
    Vue.nextTick(done);
  });

  describe('mounted', () => {
    it('renders a flash container', () => {
      expect(vm.$el.querySelector('.js-suggestions-flash')).not.toBeNull();
    });

    it('renders a container for suggestions', () => {
      expect(vm.$refs.container).not.toBeNull();
    });

    it('renders suggestions', () => {
      expect(vm.renderSuggestions).toHaveBeenCalled();
      expect(vm.$el.innerHTML.includes('Suggestion 1')).toBe(true);
      expect(vm.$el.innerHTML.includes('Suggestion 2')).toBe(true);
    });
  });

  describe('extractNewLines', () => {
    it('extracts suggested lines', () => {
      const expectedReturn = [
        { content: 'Line 1\n', lineNumber: 1 },
        { content: 'Line 2\n', lineNumber: 2 },
        { content: '- Line 3\n', lineNumber: 3 },
      ];

      expect(vm.extractNewLines(generateMockLines())).toEqual(expectedReturn);
    });

    it('increments line number for each extracted line', () => {
      expect(extractedLines[0].lineNumber).toEqual(1);
      expect(extractedLines[1].lineNumber).toEqual(2);
      expect(extractedLines[2].lineNumber).toEqual(3);
    });

    it('returns empty array if no lines are found', () => {
      const el = document.createElement('div');

      expect(vm.extractNewLines(el)).toEqual([]);
    });
  });

  describe('generateDiff', () => {
    it('generates a diff table', () => {
      expect(diffTable.querySelector('.md-suggestion-diff')).not.toBeNull();
    });

    it('generates a diff table that contains contents of `oldLineContent`', () => {
      expect(diffTable.innerHTML.includes(vm.fromContent)).toBe(true);
    });

    it('generates a diff table that contains contents the suggested lines', () => {
      extractedLines.forEach((line, i) => {
        expect(diffTable.innerHTML.includes(extractedLines[i].content)).toBe(true);
      });
    });

    it('generates a diff table with the correct line number for each suggested line', () => {
      const lines = diffTable.getElementsByClassName('qa-new-diff-line-number');

      expect([...lines][0].innerHTML).toBe('1');
      expect([...lines][1].innerHTML).toBe('2');
      expect([...lines][2].innerHTML).toBe('3');
    });
  });
});
