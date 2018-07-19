import Vue from 'vue';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import store from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';
import { noteableDataMock } from '../../notes/mock_data';

describe('DiffLineNoteForm', () => {
  let component;
  let diffFile;
  let diffLines;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);

  beforeEach(() => {
    diffFile = getDiffFileMock();
    diffLines = diffFile.highlightedDiffLines;

    component = createComponentWithStore(Vue.extend(DiffLineNoteForm), store, {
      diffFileHash: diffFile.fileHash,
      diffLines,
      line: diffLines[0],
      noteTargetLine: diffLines[0],
    });

    Object.defineProperties(component, {
      noteableData: { value: noteableDataMock },
      isLoggedIn: { value: true },
    });

    component.$mount();
  });

  describe('methods', () => {
    describe('handleCancelCommentForm', () => {
      it('should ask for confirmation when shouldConfirm and isDirty passed as truthy', () => {
        spyOn(window, 'confirm').and.returnValue(false);

        component.handleCancelCommentForm(true, true);
        expect(window.confirm).toHaveBeenCalled();
      });

      it('should ask for confirmation when one of the params false', () => {
        spyOn(window, 'confirm').and.returnValue(false);

        component.handleCancelCommentForm(true, false);
        expect(window.confirm).not.toHaveBeenCalled();

        component.handleCancelCommentForm(false, true);
        expect(window.confirm).not.toHaveBeenCalled();
      });

      it('should call cancelCommentForm with lineCode', done => {
        spyOn(window, 'confirm');
        spyOn(component, 'cancelCommentForm');
        spyOn(component, 'resetAutoSave');
        component.handleCancelCommentForm();

        expect(window.confirm).not.toHaveBeenCalled();
        component.$nextTick(() => {
          expect(component.cancelCommentForm).toHaveBeenCalledWith({
            lineCode: diffLines[0].lineCode,
          });
          expect(component.resetAutoSave).toHaveBeenCalled();

          done();
        });
      });
    });

    describe('saveNoteForm', () => {
      it('should call saveNote action with proper params', done => {
        let isPromiseCalled = false;
        const formDataSpy = spyOnDependency(DiffLineNoteForm, 'getNoteFormData').and.returnValue({
          postData: 1,
        });
        const saveNoteSpy = spyOn(component, 'saveNote').and.returnValue(
          new Promise(() => {
            isPromiseCalled = true;
            done();
          }),
        );

        component.handleSaveNote('note body');

        expect(formDataSpy).toHaveBeenCalled();
        expect(saveNoteSpy).toHaveBeenCalled();
        expect(isPromiseCalled).toEqual(true);
      });
    });
  });

  describe('mounted', () => {
    it('should init autosave', () => {
      const key = 'autosave/Note/Issue/98//DiffNote//1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_1';

      expect(component.autosave).toBeDefined();
      expect(component.autosave.key).toEqual(key);
    });
  });

  describe('template', () => {
    it('should have note form', () => {
      const { $el } = component;

      expect($el.querySelector('.js-vue-textarea')).toBeDefined();
      expect($el.querySelector('.js-vue-issue-save')).toBeDefined();
      expect($el.querySelector('.js-vue-markdown-field')).toBeDefined();
    });
  });
});
