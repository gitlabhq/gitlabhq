import Vue from 'vue';
import store from '~/notes/stores';
import issueNoteForm from '~/notes/components/note_form.vue';
import { noteableDataMock, notesDataMock } from '../mock_data';
import { keyboardDownEvent } from '../../issue_show/helpers';

describe('issue_note_form component', () => {
  let vm;
  let props;

  beforeEach(() => {
    const Component = Vue.extend(issueNoteForm);

    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: false,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      noteId: 545,
    };

    vm = new Component({
      store,
      propsData: props,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('conflicts editing', () => {
    it('should show conflict message if note changes outside the component', (done) => {
      vm.isEditing = true;
      vm.noteBody = 'Foo';
      const message = 'This comment has changed since you started editing, please review the updated comment to ensure information is not lost.';

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.js-conflict-edit-warning').textContent.replace(/\s+/g, ' ').trim(),
        ).toEqual(message);
        done();
      });
    });
  });

  describe('form', () => {
    it('should render text area with placeholder', () => {
      expect(
        vm.$el.querySelector('textarea').getAttribute('placeholder'),
      ).toEqual('Write a comment or drag your files here...');
    });

    it('should link to markdown docs', () => {
      const { markdownDocsPath } = notesDataMock;
      expect(vm.$el.querySelector(`a[href="${markdownDocsPath}"]`).textContent.trim()).toEqual('Markdown');
    });

    describe('keyboard events', () => {
      describe('up', () => {
        it('should ender edit mode', () => {
          spyOn(vm, 'editMyLastNote').and.callThrough();
          vm.$el.querySelector('textarea').value = 'Foo';
          vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(38, true));

          expect(vm.editMyLastNote).toHaveBeenCalled();
        });
      });

      describe('enter', () => {
        it('should save note when cmd+enter is pressed', () => {
          spyOn(vm, 'handleUpdate').and.callThrough();
          vm.$el.querySelector('textarea').value = 'Foo';
          vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, true));

          expect(vm.handleUpdate).toHaveBeenCalled();
        });
        it('should save note when ctrl+enter is pressed', () => {
          spyOn(vm, 'handleUpdate').and.callThrough();
          vm.$el.querySelector('textarea').value = 'Foo';
          vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, false, true));

          expect(vm.handleUpdate).toHaveBeenCalled();
        });
      });
    });

    describe('actions', () => {
      it('should be possible to cancel', (done) => {
        spyOn(vm, 'cancelHandler').and.callThrough();
        vm.isEditing = true;

        Vue.nextTick(() => {
          vm.$el.querySelector('.note-edit-cancel').click();

          Vue.nextTick(() => {
            expect(vm.cancelHandler).toHaveBeenCalled();
            done();
          });
        });
      });

      it('should be possible to update the note', (done) => {
        vm.isEditing = true;

        Vue.nextTick(() => {
          vm.$el.querySelector('textarea').value = 'Foo';
          vm.$el.querySelector('.js-vue-issue-save').click();

          Vue.nextTick(() => {
            expect(vm.isSubmitting).toEqual(true);
            done();
          });
        });
      });
    });
  });
});
