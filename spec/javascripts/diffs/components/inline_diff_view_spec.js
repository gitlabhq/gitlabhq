import Vue from 'vue';
import InlineDiffView from '~/diffs/components/inline_diff_view.vue';
import store from '~/mr_notes/stores';
import * as constants from '~/diffs/constants';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';
import discussionsMockData from '../mock_data/diff_discussions';

describe('InlineDiffView', () => {
  let component;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

  beforeEach(() => {
    const diffFile = getDiffFileMock();

    component = createComponentWithStore(Vue.extend(InlineDiffView), store, {
      diffFile,
      diffLines: diffFile.highlightedDiffLines,
    }).$mount(document.createElement('div'));
  });

  describe('methods', () => {
    describe('handleMouse', () => {
      it('should set hoveredLineCode', () => {
        expect(component.hoveredLineCode).toEqual(undefined);

        component.handleMouse('lineCode1', true);
        expect(component.hoveredLineCode).toEqual('lineCode1');

        component.handleMouse('lineCode1', false);
        expect(component.hoveredLineCode).toEqual(null);
      });
    });

    describe('getLineClass', () => {
      it('should return line class object', () => {
        const { LINE_HOVER_CLASS_NAME, LINE_UNFOLD_CLASS_NAME } = constants;
        const { MATCH_LINE_TYPE, NEW_LINE_TYPE } = constants;

        expect(component.getLineClass(component.diffLines[0])).toEqual({
          [NEW_LINE_TYPE]: NEW_LINE_TYPE,
          [LINE_UNFOLD_CLASS_NAME]: false,
          [LINE_HOVER_CLASS_NAME]: false,
        });

        component.handleMouse(component.diffLines[0].lineCode, true);
        Object.defineProperty(component, 'isLoggedIn', {
          get() {
            return true;
          },
        });

        expect(component.getLineClass(component.diffLines[0])).toEqual({
          [NEW_LINE_TYPE]: NEW_LINE_TYPE,
          [LINE_UNFOLD_CLASS_NAME]: false,
          [LINE_HOVER_CLASS_NAME]: true,
        });

        expect(component.getLineClass(component.diffLines[5])).toEqual({
          [MATCH_LINE_TYPE]: MATCH_LINE_TYPE,
          [LINE_UNFOLD_CLASS_NAME]: true,
          [LINE_HOVER_CLASS_NAME]: false,
        });
      });
    });
  });

  describe('template', () => {
    it('should have rendered diff lines', () => {
      const el = component.$el;

      expect(el.querySelectorAll('tr.line_holder').length).toEqual(6);
      expect(el.querySelectorAll('tr.line_holder.new').length).toEqual(2);
      expect(el.querySelectorAll('tr.line_holder.match').length).toEqual(1);
      expect(el.textContent.indexOf('Bad dates') > -1).toEqual(true);
    });

    it('should render discussions', done => {
      const el = component.$el;
      component.$store.dispatch('setInitialNotes', getDiscussionsMockData());

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.notes_holder').length).toEqual(1);
        expect(el.querySelectorAll('.notes_holder .note.note-discussion li').length).toEqual(5);
        expect(el.innerText.indexOf('comment 5') > -1).toEqual(true);
        component.$store.dispatch('setInitialNotes', []);

        done();
      });
    });

    it('should render new discussion forms', done => {
      const el = component.$el;
      const lines = getDiffFileMock().highlightedDiffLines;

      component.handleShowCommentForm({ lineCode: lines[0].lineCode });
      component.handleShowCommentForm({ lineCode: lines[1].lineCode });

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.js-vue-markdown-field').length).toEqual(2);
        expect(el.querySelectorAll('tr')[1].classList.contains('notes_holder')).toEqual(true);
        expect(el.querySelectorAll('tr')[3].classList.contains('notes_holder')).toEqual(true);

        done();
      });
    });
  });
});
