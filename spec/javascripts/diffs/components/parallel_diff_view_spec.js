import Vue from 'vue';
import ParallelDiffView from '~/diffs/components/parallel_diff_view.vue';
import store from '~/mr_notes/stores';
import * as constants from '~/diffs/constants';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';

describe('ParallelDiffView', () => {
  let component;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);

  beforeEach(() => {
    const diffFile = getDiffFileMock();

    component = createComponentWithStore(Vue.extend(ParallelDiffView), store, {
      diffFile,
      diffLines: diffFile.parallelDiffLines,
    }).$mount();
  });

  describe('computed', () => {
    describe('parallelDiffLines', () => {
      it('should normalize lines for empty cells', () => {
        expect(component.parallelDiffLines[0].left.type).toEqual(constants.EMPTY_CELL_TYPE);
        expect(component.parallelDiffLines[1].left.type).toEqual(constants.EMPTY_CELL_TYPE);
      });
    });
  });
});
