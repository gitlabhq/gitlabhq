import Vue from 'vue';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import store from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';

fdescribe('DiffLineNoteForm', () => {
  let component;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);

  beforeEach(() => {
    const diffFile = getDiffFileMock();
    const diffLines = diffFile.highlightedDiffLines;

    component = createComponentWithStore(Vue.extend(DiffLineNoteForm), store, {
      diffFile,
      diffLines,
      line: diffLines[0],
      noteTargetLine: diffLines[0],
    }).$mount(document.createElement('div'));
  });

  describe('methods', () => {
    describe('handleCancelCommentForm', () => {
      it('should call cancelCommentForm with lineCode', () => {
        // spyOn(component.cancelCommentForm);
        // component.handleCancelCommentForm();
        // expect(component.cancelCommentForm).toHaveBeenCalled();
      });
    });
  });
});
