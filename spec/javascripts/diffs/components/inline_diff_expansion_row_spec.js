import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import InlineDiffExpansionRow from '~/diffs/components/inline_diff_expansion_row.vue';
import diffFileMockData from '../mock_data/diff_file';

describe('InlineDiffExpansionRow', () => {
  const matchLine = diffFileMockData.highlighted_diff_lines[5];

  const createComponent = (options = {}) => {
    const cmp = Vue.extend(InlineDiffExpansionRow);
    const defaults = {
      fileHash: diffFileMockData.file_hash,
      contextLinesPath: 'contextLinesPath',
      line: matchLine,
      isTop: false,
      isBottom: false,
    };
    const props = Object.assign({}, defaults, options);

    return createComponentWithStore(cmp, createStore(), props).$mount();
  };

  describe('template', () => {
    it('should render expansion row for match lines', () => {
      const vm = createComponent();

      expect(vm.$el.classList.contains('line_expansion')).toBe(true);
    });
  });
});
