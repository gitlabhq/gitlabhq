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
      filePath: diffFileMockData.file_path,
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

  describe('sets coverage title and class', () => {
    it('for lines with coverage', done => {
      vm.$nextTick()
        .then(() => {
          const name = diffFileMockData.file_path;
          const line = thisLine.new_line;

          vm.$store.state.diffs.coverageFiles = { files: { [name]: { [line]: 5 } } };

          return vm.$nextTick();
        })
        .then(() => {
          const coverage = vm.$el.querySelector('.line-coverage');

          expect(coverage.title).toContain('Test coverage: 5 hits');
          expect(coverage.classList).toContain('coverage');
        })
        .then(done)
        .catch(done.fail);
    });

    it('for lines without coverage', done => {
      vm.$nextTick()
        .then(() => {
          const name = diffFileMockData.file_path;
          const line = thisLine.new_line;

          vm.$store.state.diffs.coverageFiles = { files: { [name]: { [line]: 0 } } };

          return vm.$nextTick();
        })
        .then(() => {
          const coverage = vm.$el.querySelector('.line-coverage');

          expect(coverage.title).toContain('No test coverage');
          expect(coverage.classList).toContain('no-coverage');
        })
        .then(done)
        .catch(done.fail);
    });

    it('for unknown lines', done => {
      vm.$nextTick()
        .then(() => {
          vm.$store.state.diffs.coverageFiles = {};

          return vm.$nextTick();
        })
        .then(() => {
          const coverage = vm.$el.querySelector('.line-coverage');

          expect(coverage.title).not.toContain('Coverage');
          expect(coverage.classList).not.toContain('coverage');
          expect(coverage.classList).not.toContain('no-coverage');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
