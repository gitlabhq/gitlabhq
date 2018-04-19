
import Vue from 'vue';
import store from '~/notes/stores';
import noteBody from '~/notes/components/note_body.vue';
import { noteableDataMock, notesDataMock, note } from '../mock_data';

describe('issue_note_body component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(noteBody);

    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    vm = new Component({
      store,
      propsData: {
        note,
        canEdit: true,
        canAwardEmoji: true,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render the note', () => {
    expect(vm.$el.querySelector('.note-text').innerHTML).toEqual(note.note_html);
  });

  it('should render awards list', () => {
    expect(vm.$el.querySelector('.js-awards-block button [data-name="baseball"]')).not.toBeNull();
    expect(vm.$el.querySelector('.js-awards-block button [data-name="bath_tone3"]')).not.toBeNull();
  });

  describe('isEditing', () => {
    beforeEach((done) => {
      vm.isEditing = true;
      Vue.nextTick(done);
    });

    it('renders edit form', () => {
      expect(vm.$el.querySelector('textarea.js-task-list-field')).not.toBeNull();
    });

    it('adds autosave', () => {
      const autosaveKey = `autosave/Note/${note.noteable_type}/${note.id}`;

      expect(vm.autosave).toExist();
      expect(vm.autosave.key).toEqual(autosaveKey);
    });
  });
});
