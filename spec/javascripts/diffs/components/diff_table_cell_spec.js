import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import DiffTableCell from '~/diffs/components/diff_table_cell.vue';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffTableCell', () => {
  const createComponent = options =>
    createComponentWithStore(Vue.extend(DiffTableCell), createStore(), {
      line: diffFileMockData.highlighted_diff_lines[0],
      fileHash: diffFileMockData.file_hash,
      contextLinesPath: 'contextLinesPath',
      ...options,
    }).$mount();

  it('does not highlight row when isHighlighted prop is false', done => {
    const vm = createComponent({ isHighlighted: false });

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.classList).not.toContain('hll');
      })
      .then(done)
      .catch(done.fail);
  });

  it('highlights row when isHighlighted prop is true', done => {
    const vm = createComponent({ isHighlighted: true });

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.classList).toContain('hll');
      })
      .then(done)
      .catch(done.fail);
  });
});
