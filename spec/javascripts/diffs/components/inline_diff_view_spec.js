import Vue from 'vue';
import '~/behaviors/markdown/render_gfm';
import { createStore } from 'ee_else_ce/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import InlineDiffView from '~/diffs/components/inline_diff_view.vue';
import diffFileMockData from '../mock_data/diff_file';
import discussionsMockData from '../mock_data/diff_discussions';

describe('InlineDiffView', () => {
  let component;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];
  const notesLength = getDiscussionsMockData()[0].notes.length;

  beforeEach(done => {
    const diffFile = getDiffFileMock();

    const store = createStore();

    store.dispatch('diffs/setInlineDiffViewType');
    component = createComponentWithStore(Vue.extend(InlineDiffView), store, {
      diffFile,
      diffLines: diffFile.highlighted_diff_lines,
    }).$mount();

    Vue.nextTick(done);
  });

  describe('template', () => {
    it('should have rendered diff lines', () => {
      const el = component.$el;

      expect(el.querySelectorAll('tr.line_holder').length).toEqual(5);
      expect(el.querySelectorAll('tr.line_holder.new').length).toEqual(2);
      expect(el.querySelectorAll('tr.line_expansion.match').length).toEqual(1);
      expect(el.textContent.indexOf('Bad dates')).toBeGreaterThan(-1);
    });

    it('should render discussions', done => {
      const el = component.$el;
      component.diffLines[1].discussions = getDiscussionsMockData();
      component.diffLines[1].discussionsExpanded = true;

      Vue.nextTick(() => {
        expect(el.querySelectorAll('.notes_holder').length).toEqual(1);
        expect(el.querySelectorAll('.notes_holder .note').length).toEqual(notesLength + 1);
        expect(el.innerText.indexOf('comment 5')).toBeGreaterThan(-1);
        component.$store.dispatch('setInitialNotes', []);

        done();
      });
    });
  });
});
