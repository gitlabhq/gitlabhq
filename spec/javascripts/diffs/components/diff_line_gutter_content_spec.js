import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import DiffLineGutterContent from '~/diffs/components/diff_line_gutter_content.vue';
import { createStore } from '~/mr_notes/stores';
import discussionsMockData from '../mock_data/diff_discussions';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffLineGutterContent', () => {
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);
  const createComponent = (options = {}) => {
    const cmp = Vue.extend(DiffLineGutterContent);
    const props = Object.assign({}, options);
    props.line = {
      line_code: 'LC_42',
      type: 'new',
      old_line: null,
      new_line: 1,
      discussions: [{ ...discussionsMockData }],
      text: '+<span id="LC1" class="line" lang="plaintext">  - Bad dates</span>\n',
      rich_text: '+<span id="LC1" class="line" lang="plaintext">  - Bad dates</span>\n',
      meta_data: null,
    };
    props.fileHash = getDiffFileMock().file_hash;
    props.contextLinesPath = '/context/lines/path';

    return createComponentWithStore(cmp, createStore(), props).$mount();
  };

  describe('computed', () => {
    describe('lineHref', () => {
      it('should prepend # to lineCode', () => {
        const lineCode = 'LC_42';
        const component = createComponent();

        expect(component.lineHref).toEqual(`#${lineCode}`);
      });

      it('should return # if there is no lineCode', () => {
        const component = createComponent();
        component.line.line_code = '';

        expect(component.lineHref).toEqual('#');
      });
    });

    describe('discussions, hasDiscussions, shouldShowAvatarsOnGutter', () => {
      it('should return empty array when there is no discussion', () => {
        const component = createComponent();
        component.line.discussions = [];

        expect(component.hasDiscussions).toEqual(false);
        expect(component.shouldShowAvatarsOnGutter).toEqual(false);
      });

      it('should return discussions for the given lineCode', () => {
        const cmp = Vue.extend(DiffLineGutterContent);
        const props = {
          line: getDiffFileMock().highlighted_diff_lines[1],
          fileHash: getDiffFileMock().file_hash,
          showCommentButton: true,
          contextLinesPath: '/context/lines/path',
        };
        props.line.discussions = [Object.assign({}, discussionsMockData)];
        const component = createComponentWithStore(cmp, createStore(), props).$mount();

        expect(component.hasDiscussions).toEqual(true);
        expect(component.shouldShowAvatarsOnGutter).toEqual(true);
      });
    });
  });

  describe('template', () => {
    it('should render comment button', () => {
      const component = createComponent({
        showCommentButton: true,
      });
      Object.defineProperty(component, 'isLoggedIn', {
        get() {
          return true;
        },
      });

      expect(component.$el.querySelector('.js-add-diff-note-button')).toBeDefined();
    });

    it('should render line link', () => {
      const lineNumber = 42;
      const lineCode = `LC_${lineNumber}`;
      const component = createComponent({ lineNumber, lineCode });
      const link = component.$el.querySelector('a');

      expect(link.href.indexOf(`#${lineCode}`)).toBeGreaterThan(-1);
      expect(link.dataset.linenumber).toEqual(lineNumber.toString());
    });

    it('should render user avatars', () => {
      const component = createComponent({
        showCommentButton: true,
        lineCode: getDiffFileMock().highlighted_diff_lines[1].line_code,
      });

      expect(component.$el.querySelector('.diff-comment-avatar-holders')).not.toBe(null);
    });
  });
});
