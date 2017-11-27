import Vue from 'vue';
import DiffNoteAvatars from '~/diff_notes/components/diff_note_avatars.vue';
import DiscussionModel from '~/diff_notes/models/discussion';
import { createNote } from '../mock_data';

describe('diff_note_avatars', () => {
  let vm;
  let discussion;

  beforeEach(() => {
    window.notes = jasmine.createSpyObj('notes', ['onAddDiffNote']);
    const Component = Vue.extend(DiffNoteAvatars);

    const discussionId = '1234abcd';
    discussion = new DiscussionModel(discussionId);
    discussion.createNote(createNote());

    window.CommentsStore.state = {
      [discussionId]: discussion,
    };

    vm = new Component({
      propsData: {
        discussionId: discussion.id,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
    delete window.CommentsStore.state;
  });

  it('includes discussion ID in class name', () => {
    expect(vm.$el.classList).toContain(`js-diff-avatars-${discussion.id}`);
  });

  describe('avatars', () => {
    it('shown by default', () => {
      expect(vm.showCollapseButton).toBe(false);
      expect(vm.$el.querySelector('.diff-notes-collapse')).toBe(null);
      expect(vm.$el.querySelector('.diff-comment-avatar')).toBeTruthy();
    });
  });
});
