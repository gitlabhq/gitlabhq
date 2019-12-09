import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import DiffExpansionCell from '~/diffs/components/diff_expansion_cell.vue';
import diffFileMockData from '../mock_data/diff_file';

const EXPAND_UP_CLASS = '.js-unfold';
const EXPAND_DOWN_CLASS = '.js-unfold-down';
const EXPAND_ALL_CLASS = '.js-unfold-all';

describe('DiffExpansionCell', () => {
  const matchLine = diffFileMockData.highlighted_diff_lines[5];

  const createComponent = (options = {}) => {
    const cmp = Vue.extend(DiffExpansionCell);
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

  describe('top row', () => {
    it('should have "expand up" and "show all" option', () => {
      const vm = createComponent({
        isTop: true,
      });
      const el = vm.$el;

      expect(el.querySelector(EXPAND_UP_CLASS)).not.toBe(null);
      expect(el.querySelector(EXPAND_DOWN_CLASS)).toBe(null);
      expect(el.querySelector(EXPAND_ALL_CLASS)).not.toBe(null);
    });
  });

  describe('middle row', () => {
    it('should have "expand down", "show all", "expand up" option', () => {
      const vm = createComponent();
      const el = vm.$el;

      expect(el.querySelector(EXPAND_UP_CLASS)).not.toBe(null);
      expect(el.querySelector(EXPAND_DOWN_CLASS)).not.toBe(null);
      expect(el.querySelector(EXPAND_ALL_CLASS)).not.toBe(null);
    });
  });

  describe('bottom row', () => {
    it('should have "expand down" and "show all" option', () => {
      const vm = createComponent({
        isBottom: true,
      });
      const el = vm.$el;

      expect(el.querySelector(EXPAND_UP_CLASS)).toBe(null);
      expect(el.querySelector(EXPAND_DOWN_CLASS)).not.toBe(null);
      expect(el.querySelector(EXPAND_ALL_CLASS)).not.toBe(null);
    });
  });
});
