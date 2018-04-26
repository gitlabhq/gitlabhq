import Vue from 'vue';
import ParallelDiffView from '~/diffs/components/parallel_diff_view.vue';
import store from '~/mr_notes/stores';
import * as constants from '~/diffs/constants';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';
import discussionsMockData from '../mock_data/diff_discussions';

describe('ParallelDiffView', () => {
  let component;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

  beforeEach(() => {
    const diffFile = getDiffFileMock();

    component = createComponentWithStore(Vue.extend(ParallelDiffView), store, {
      diffFile,
      diffLines: diffFile.parallelDiffLines,
    }).$mount(document.createElement('div'));
  });

  describe('computed', () => {
    describe('parallelDiffLines', () => {
      it('should normalize lines for empty cells', () => {
        expect(component.parallelDiffLines[0].left.type).toEqual(constants.EMPTY_CELL_TYPE);
        expect(component.parallelDiffLines[1].left.type).toEqual(constants.EMPTY_CELL_TYPE);
      });
    });
  });

  describe('methods', () => {
    describe('hasDiscussion', () => {
      it('it should return true if there is a discussion either for left or right section', () => {
        Object.defineProperty(component, 'discussionsByLineCode', {
          get() {
            return { line_42: true };
          },
        });

        expect(component.hasDiscussion({ left: {}, right: {} })).toEqual(undefined);
        expect(component.hasDiscussion({ left: { lineCode: 'line_42' }, right: {} })).toEqual(true);
        expect(component.hasDiscussion({ left: {}, right: { lineCode: 'line_42' } })).toEqual(true);
      });
    });

    describe('getClassName', () => {
      it('should return line class object', () => {
        const { LINE_HOVER_CLASS_NAME, LINE_UNFOLD_CLASS_NAME } = constants;
        const { MATCH_LINE_TYPE, NEW_LINE_TYPE, LINE_POSITION_RIGHT } = constants;

        expect(component.getClassName(component.diffLines[1], LINE_POSITION_RIGHT)).toEqual({
          [NEW_LINE_TYPE]: NEW_LINE_TYPE,
          [LINE_UNFOLD_CLASS_NAME]: false,
          [LINE_HOVER_CLASS_NAME]: false,
        });

        const eventMock = {
          target: component.$refs.rightLines[1],
        };

        component.handleMouse(eventMock, component.diffLines[1], true);
        Object.defineProperty(component, 'isLoggedIn', {
          get() {
            return true;
          },
        });

        expect(component.getClassName(component.diffLines[1], LINE_POSITION_RIGHT)).toEqual({
          [NEW_LINE_TYPE]: NEW_LINE_TYPE,
          [LINE_UNFOLD_CLASS_NAME]: false,
          [LINE_HOVER_CLASS_NAME]: true,
        });

        expect(component.getClassName(component.diffLines[5], LINE_POSITION_RIGHT)).toEqual({
          [MATCH_LINE_TYPE]: MATCH_LINE_TYPE,
          [LINE_UNFOLD_CLASS_NAME]: true,
          [LINE_HOVER_CLASS_NAME]: false,
        });
      });
    });

    describe('handleMouse', () => {
      it('should set hovered line code and line section to null when isHover is false', () => {
        const rightLineEventMock = { target: component.$refs.rightLines[1] };
        expect(component.hoveredLineCode).toEqual(undefined);
        expect(component.hoveredSection).toEqual(undefined);

        component.handleMouse(rightLineEventMock, null, false);
        expect(component.hoveredLineCode).toEqual(null);
        expect(component.hoveredSection).toEqual(null);
      });

      it('should set hovered line code and line section for right section', () => {
        const rightLineEventMock = { target: component.$refs.rightLines[1] };
        component.handleMouse(rightLineEventMock, component.diffLines[1], true);
        expect(component.hoveredLineCode).toEqual(component.diffLines[1].right.lineCode);
        expect(component.hoveredSection).toEqual(constants.LINE_POSITION_RIGHT);
      });

      it('should set hovered line code and line section for left section', () => {
        const leftLineEventMock = { target: component.$refs.leftLines[2] };
        component.handleMouse(leftLineEventMock, component.diffLines[2], true);
        expect(component.hoveredLineCode).toEqual(component.diffLines[2].left.lineCode);
        expect(component.hoveredSection).toEqual(constants.LINE_POSITION_LEFT);
      });
    });

    describe('shouldRenderDiscussions', () => {
      it('should return true if there is a discussion on left side and it is expanded', () => {
        const line = { left: { lineCode: 'lineCode1' } };
        spyOn(component, 'isDiscussionExpanded').and.returnValue(true);
        Object.defineProperty(component, 'discussionsByLineCode', {
          get() {
            return {
              [line.left.lineCode]: true,
            };
          },
        });

        expect(component.shouldRenderDiscussions(line, constants.LINE_POSITION_LEFT)).toEqual(true);
        expect(component.isDiscussionExpanded).toHaveBeenCalledWith(line.left.lineCode);
      });

      it('should return false if there is a discussion on left side but it is collapsed', () => {
        const line = { left: { lineCode: 'lineCode1' } };
        spyOn(component, 'isDiscussionExpanded').and.returnValue(false);
        Object.defineProperty(component, 'discussionsByLineCode', {
          get() {
            return {
              [line.left.lineCode]: true,
            };
          },
        });

        expect(component.shouldRenderDiscussions(line, constants.LINE_POSITION_LEFT)).toEqual(
          false,
        );
      });

      it('should return false for discussions on the right side if there is no line type', () => {
        const CUSTOM_RIGHT_LINE_TYPE = 'CUSTOM_RIGHT_LINE_TYPE';
        const line = { right: { lineCode: 'lineCode1', type: CUSTOM_RIGHT_LINE_TYPE } };
        spyOn(component, 'isDiscussionExpanded').and.returnValue(true);
        Object.defineProperty(component, 'discussionsByLineCode', {
          get() {
            return {
              [line.right.lineCode]: true,
            };
          },
        });

        expect(component.shouldRenderDiscussions(line, constants.LINE_POSITION_RIGHT)).toEqual(
          CUSTOM_RIGHT_LINE_TYPE,
        );
      });
    });

    describe('hasAnyExpandedDiscussion', () => {
      const LINE_CODE_LEFT = 'LINE_CODE_LEFT';
      const LINE_CODE_RIGHT = 'LINE_CODE_RIGHT';

      it('should return true if there is a discussion either on the left or the right side', () => {
        const mockLineOne = {
          right: { lineCode: LINE_CODE_RIGHT },
          left: {},
        };
        const mockLineTwo = {
          left: { lineCode: LINE_CODE_LEFT },
          right: {},
        };

        spyOn(component, 'isDiscussionExpanded').and.callFake(lc => lc === LINE_CODE_RIGHT);
        expect(component.hasAnyExpandedDiscussion(mockLineOne)).toEqual(true);
        expect(component.hasAnyExpandedDiscussion(mockLineTwo)).toEqual(false);
      });
    });
  });

  describe('template', () => {
    it('should have rendered diff lines', () => {
      const el = component.$el;

      expect(el.querySelectorAll('tr.line_holder.parallel').length).toEqual(6);
      expect(el.querySelectorAll('td.empty-cell').length).toEqual(4);
      expect(el.querySelectorAll('td.line_content.parallel.right-side').length).toEqual(6);
      expect(el.querySelectorAll('td.line_content.parallel.left-side').length).toEqual(6);
      expect(el.querySelectorAll('td.match').length).toEqual(4);
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
      const lines = getDiffFileMock().parallelDiffLines;

      component.handleShowCommentForm({ lineCode: lines[0].lineCode });
      component.handleShowCommentForm({ lineCode: lines[1].lineCode });

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.js-vue-markdown-field').length).toEqual(2);
        expect(el.querySelectorAll('tr')[1].classList.contains('notes_holder')).toEqual(true);
        expect(el.querySelectorAll('tr')[3].classList.contains('notes_holder')).toEqual(true);

        store.state.diffs.diffLineCommentForms = {};

        done();
      });
    });
  });
});
