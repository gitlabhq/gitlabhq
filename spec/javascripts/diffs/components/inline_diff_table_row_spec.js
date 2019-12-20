import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import InlineDiffTableRow from '~/diffs/components/inline_diff_table_row.vue';
import diffFileMockData from '../mock_data/diff_file';

describe('InlineDiffTableRow', () => {
  let vm;
  const thisLine = diffFileMockData.highlighted_diff_lines[0];

  beforeEach(() => {
    vm = createComponentWithStore(Vue.extend(InlineDiffTableRow), createStore(), {
      line: thisLine,
      fileHash: diffFileMockData.file_hash,
      contextLinesPath: 'contextLinesPath',
      isHighlighted: false,
    }).$mount();
  });

  it('does not add hll class to line content when line does not match highlighted row', done => {
    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.line_content').classList).not.toContain('hll');
      })
      .then(done)
      .catch(done.fail);
  });

  it('adds hll class to lineContent when line is the highlighted row', done => {
    vm.$nextTick()
      .then(() => {
        vm.$store.state.diffs.highlightedRow = thisLine.line_code;

        return vm.$nextTick();
      })
      .then(() => {
        expect(vm.$el.querySelector('.line_content').classList).toContain('hll');
      })
      .then(done)
      .catch(done.fail);
  });
});
