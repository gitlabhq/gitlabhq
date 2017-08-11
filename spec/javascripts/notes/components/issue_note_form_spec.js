import Vue from 'vue';
import store from '~/notes/stores';
import issueNote from '~/notes/components/issue_note.vue';
import { issueDataMock, notesDataMock } from '../mock_data';

fdescribe('issue_note_form component', () => {
  let vm;
  let props;

  beforeEach(() => {
    const Component = Vue.extend(issueNote);

    store.dispatch('setIssueData', issueDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: true,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      noteId: 545,
      saveButtonTitle: 'Save comment',
    };

    vm = new Component({
      store,
      propsData: props,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('conflicts editing', (done) => {
    it('should show conflict message if note changes outside the component', () => {
      vm.noteBody = 'Foo';

      Vue.nextTick(() => {
        console.log('', vm.$el);

        done();
      });
    });
  });

  describe('form', () => {
    it('should render text area with placeholder', () => {

    });

    it('should link to markdown docs', () => {

    });

    it('should link to quick actions docs', () => {

    });

    it('should preview the content', () => {

    });

    it('should allow quick actions', () => {

    });

    describe('keyboard events', () => {
      describe('up', () => {
        it('should ender edit mode', () => {

        });
      });

      describe('enter', () => {
        it('should submit note', () => {

        });
      });

      describe('esc', () => {
        it('should show exit', () => {

        });
      });
    });

    describe('actions', () => {
      it('should be possible to cancel', () => {

      });

      it('should be possible to update the note', () => {

      });

      it('should not be possible to save an empty note', () => {

      });
    });
  });
});
