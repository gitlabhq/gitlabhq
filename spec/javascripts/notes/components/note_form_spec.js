import { shallowMount, createLocalVue } from '@vue/test-utils';
import createStore from '~/notes/stores';
import NoteForm from '~/notes/components/note_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { noteableDataMock, notesDataMock } from '../mock_data';

describe('issue_note_form component', () => {
  let store;
  let wrapper;
  let props;

  beforeEach(() => {
    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: false,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      noteId: '545',
    };

    const localVue = createLocalVue();
    wrapper = shallowMount(NoteForm, {
      store,
      propsData: props,
      // see https://gitlab.com/gitlab-org/gitlab-ce/issues/56317 for the following
      localVue,
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('noteHash', () => {
    it('returns note hash string based on `noteId`', () => {
      expect(wrapper.vm.noteHash).toBe(`#note_${props.noteId}`);
    });

    it('return note hash as `#` when `noteId` is empty', done => {
      wrapper.setProps({
        ...props,
        noteId: '',
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.noteHash).toBe('#');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('conflicts editing', () => {
    it('should show conflict message if note changes outside the component', done => {
      wrapper.setProps({
        ...props,
        isEditing: true,
        noteBody: 'Foo',
      });

      const message =
        'This comment has changed since you started editing, please review the updated comment to ensure information is not lost.';

      wrapper.vm
        .$nextTick()
        .then(() => {
          const conflictWarning = wrapper.find('.js-conflict-edit-warning');

          expect(conflictWarning.exists()).toBe(true);
          expect(
            conflictWarning
              .text()
              .replace(/\s+/g, ' ')
              .trim(),
          ).toBe(message);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('form', () => {
    it('should render text area with placeholder', () => {
      const textarea = wrapper.find('textarea');

      expect(textarea.attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });

    it('should link to markdown docs', () => {
      const { markdownDocsPath } = notesDataMock;
      const markdownField = wrapper.find(MarkdownField);
      const markdownFieldProps = markdownField.props();

      expect(markdownFieldProps.markdownDocsPath).toBe(markdownDocsPath);
    });

    describe('keyboard events', () => {
      let textarea;

      beforeEach(() => {
        textarea = wrapper.find('textarea');
        textarea.setValue('Foo');
      });

      describe('up', () => {
        it('should ender edit mode', () => {
          // TODO: do not spy on vm
          spyOn(wrapper.vm, 'editMyLastNote').and.callThrough();

          textarea.trigger('keydown.up');

          expect(wrapper.vm.editMyLastNote).toHaveBeenCalled();
        });
      });

      describe('enter', () => {
        it('should save note when cmd+enter is pressed', () => {
          textarea.trigger('keydown.enter', { metaKey: true });

          const { handleFormUpdate } = wrapper.emitted();

          expect(handleFormUpdate.length).toBe(1);
        });

        it('should save note when ctrl+enter is pressed', () => {
          textarea.trigger('keydown.enter', { ctrlKey: true });

          const { handleFormUpdate } = wrapper.emitted();

          expect(handleFormUpdate.length).toBe(1);
        });
      });
    });

    describe('actions', () => {
      it('should be possible to cancel', done => {
        // TODO: do not spy on vm
        spyOn(wrapper.vm, 'cancelHandler').and.callThrough();
        wrapper.setProps({
          ...props,
          isEditing: true,
        });

        wrapper.vm
          .$nextTick()
          .then(() => {
            const cancelButton = wrapper.find('.note-edit-cancel');
            cancelButton.trigger('click');

            expect(wrapper.vm.cancelHandler).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });

      it('should be possible to update the note', done => {
        wrapper.setProps({
          ...props,
          isEditing: true,
        });

        wrapper.vm
          .$nextTick()
          .then(() => {
            const textarea = wrapper.find('textarea');
            textarea.setValue('Foo');
            const saveButton = wrapper.find('.js-vue-issue-save');
            saveButton.trigger('click');

            expect(wrapper.vm.isSubmitting).toEqual(true);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
