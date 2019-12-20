import Vue from 'vue';
import createStore from '~/notes/stores';
import awardsNote from '~/notes/components/note_awards_list.vue';
import { noteableDataMock, notesDataMock } from '../mock_data';

describe('note_awards_list component', () => {
  let store;
  let vm;
  let awardsMock;

  beforeEach(() => {
    const Component = Vue.extend(awardsNote);

    store = createStore();
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
        noteId: '545',
        canAwardEmoji: true,
        toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render awarded emojis', () => {
    expect(vm.$el.querySelector('.js-awards-block button [data-name="flag_tz"]')).toBeDefined();
    expect(
      vm.$el.querySelector('.js-awards-block button [data-name="cartwheel_tone3"]'),
    ).toBeDefined();
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

  describe('when the user name contains special HTML characters', () => {
    const createAwardEmoji = (_, index) => ({
      name: 'art',
      user: { id: index, name: `&<>"\`'-${index}`, username: `user-${index}` },
    });

    const mountComponent = () => {
      const Component = Vue.extend(awardsNote);
      vm = new Component({
        store,
        propsData: {
          awards: awardsMock,
          noteAuthorId: 0,
          noteId: '545',
          canAwardEmoji: true,
          toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
        },
      }).$mount();
    };

    const findTooltip = () =>
      vm.$el.querySelector('[data-original-title]').getAttribute('data-original-title');

    it('should only escape & and " characters', () => {
      awardsMock = [...new Array(1)].map(createAwardEmoji);
      mountComponent();
      const escapedName = awardsMock[0].user.name.replace(/&/g, '&amp;').replace(/"/g, '&quot;');

      expect(vm.$el.querySelector('[data-original-title]').outerHTML).toContain(escapedName);
    });

    it('should not escape special HTML characters twice when only 1 person awarded', () => {
      awardsMock = [...new Array(1)].map(createAwardEmoji);
      mountComponent();

      awardsMock.forEach(award => {
        expect(findTooltip()).toContain(award.user.name);
      });
    });

    it('should not escape special HTML characters twice when 2 people awarded', () => {
      awardsMock = [...new Array(2)].map(createAwardEmoji);
      mountComponent();

      awardsMock.forEach(award => {
        expect(findTooltip()).toContain(award.user.name);
      });
    });

    it('should not escape special HTML characters twice when more than 10 people awarded', () => {
      awardsMock = [...new Array(11)].map(createAwardEmoji);
      mountComponent();

      // Testing only the first 10 awards since 11 onward will not be displayed.
      awardsMock.slice(0, 10).forEach(award => {
        expect(findTooltip()).toContain(award.user.name);
      });
    });
  });

  describe('when the user cannot award emoji', () => {
    beforeEach(() => {
      const Component = Vue.extend(awardsNote);

      vm = new Component({
        store,
        propsData: {
          awards: awardsMock,
          noteAuthorId: 2,
          noteId: '545',
          canAwardEmoji: false,
          toggleAwardPath: '/gitlab-org/gitlab-foss/notes/545/toggle_award_emoji',
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
