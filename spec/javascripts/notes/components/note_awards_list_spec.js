import Vue from 'vue';
import store from '~/notes/stores';
import awardsNote from '~/notes/components/note_awards_list.vue';
import { noteableDataMock, notesDataMock } from '../mock_data';

describe('note_awards_list component', () => {
  let vm;
  let awardsMock;

  beforeEach(() => {
    const Component = Vue.extend(awardsNote);

    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);
    awardsMock = [
      {
        name: 'flag_tz',
        user: { id: 1, name: 'Administrator', username: 'root' },
      },
      {
        name: 'cartwheel_tone3',
        user: { id: 12, name: 'Bobbie Stehr', username: 'erin' },
      },
    ];

    vm = new Component({
      store,
      propsData: {
        awards: awardsMock,
        noteAuthorId: 2,
        noteId: 545,
        canAwardEmoji: true,
        toggleAwardPath: '/gitlab-org/gitlab-ce/notes/545/toggle_award_emoji',
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render awarded emojis', () => {
    expect(vm.$el.querySelector('.js-awards-block button [data-name="flag_tz"]')).toBeDefined();
    expect(vm.$el.querySelector('.js-awards-block button [data-name="cartwheel_tone3"]')).toBeDefined();
  });

  it('should be possible to remove awarded emoji', () => {
    spyOn(vm, 'handleAward').and.callThrough();
    spyOn(vm, 'toggleAwardRequest').and.callThrough();
    vm.$el.querySelector('.js-awards-block button').click();

    expect(vm.handleAward).toHaveBeenCalledWith('flag_tz');
    expect(vm.toggleAwardRequest).toHaveBeenCalled();
  });

  it('should be possible to add new emoji', () => {
    expect(vm.$el.querySelector('.js-add-award')).toBeDefined();
  });

  describe('when the user cannot award emoji', () => {
    beforeEach(() => {
      const Component = Vue.extend(awardsNote);

      vm = new Component({
        store,
        propsData: {
          awards: awardsMock,
          noteAuthorId: 2,
          noteId: 545,
          canAwardEmoji: false,
          toggleAwardPath: '/gitlab-org/gitlab-ce/notes/545/toggle_award_emoji',
        },
      }).$mount();
    });

    it('should not be possible to remove awarded emoji', () => {
      spyOn(vm, 'toggleAwardRequest').and.callThrough();

      vm.$el.querySelector('.js-awards-block button').click();

      expect(vm.toggleAwardRequest).not.toHaveBeenCalled();
    });

    it('should not be possible to add new emoji', () => {
      expect(vm.$el.querySelector('.js-add-award')).toBeNull();
    });
  });
});
