
import Vue from 'vue';
import store from '~/notes/stores';
import noteBody from '~/notes/components/issue_note_body.vue';
import { issueDataMock, notesDataMock, note } from '../mock_data';

describe('issue_note_body component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(noteBody);

    store.dispatch('setIssueData', issueDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
      propsData: {
        note,
        canEdit: true,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render the note', () => {
    expect(vm.$el.querySelector('.note-text').innerHTML).toEqual(note.note_html);
  });

  it('should be render form if user is editing', (done) => {
    vm.isEditing = true;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('textarea.js-task-list-field')).toBeDefined();
      done();
    });
  });

  it('should render awards list', () => {
    expect(vm.$el.querySelector('.js-awards-block button [data-name="baseball"]')).toBeDefined();
    expect(vm.$el.querySelector('.js-awards-block button [data-name="bath_tone3"]')).toBeDefined();
  });
});
