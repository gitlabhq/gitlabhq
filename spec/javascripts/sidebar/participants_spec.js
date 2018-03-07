import Vue from 'vue';
import participants from '~/sidebar/components/participants/participants.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const PARTICIPANT = {
  id: 1,
  state: 'active',
  username: 'marcene',
  name: 'Allie Will',
  web_url: 'foo.com',
  avatar_url: 'gravatar.com/avatar/xxx',
};

const PARTICIPANT_LIST = [
  PARTICIPANT,
  { ...PARTICIPANT, id: 2 },
  { ...PARTICIPANT, id: 3 },
];

describe('Participants', function () {
  let vm;
  let Participants;

  beforeEach(() => {
    Participants = Vue.extend(participants);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('collapsed sidebar state', () => {
    it('shows loading spinner when loading', () => {
      vm = mountComponent(Participants, {
        loading: true,
      });

      expect(vm.$el.querySelector('.js-participants-collapsed-loading-icon')).toBeDefined();
    });

    it('shows participant count when given', () => {
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
      });
      const countEl = vm.$el.querySelector('.js-participants-collapsed-count');

      expect(countEl.textContent.trim()).toBe(`${PARTICIPANT_LIST.length}`);
    });

    it('shows full participant count when there are hidden participants', () => {
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 1,
      });
      const countEl = vm.$el.querySelector('.js-participants-collapsed-count');

      expect(countEl.textContent.trim()).toBe(`${PARTICIPANT_LIST.length}`);
    });
  });

  describe('expanded sidebar state', () => {
    it('shows loading spinner when loading', () => {
      vm = mountComponent(Participants, {
        loading: true,
      });

      expect(vm.$el.querySelector('.js-participants-expanded-loading-icon')).toBeDefined();
    });

    it('when only showing visible participants, shows an avatar only for each participant under the limit', (done) => {
      const numberOfLessParticipants = 2;
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants,
      });
      vm.isShowingMoreParticipants = false;

      Vue.nextTick()
        .then(() => {
          const participantEls = vm.$el.querySelectorAll('.js-participants-author');

          expect(participantEls.length).toBe(numberOfLessParticipants);
        })
        .then(done)
        .catch(done.fail);
    });

    it('when only showing all participants, each has an avatar', (done) => {
      const numberOfLessParticipants = 2;
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants,
      });
      vm.isShowingMoreParticipants = true;

      Vue.nextTick()
        .then(() => {
          const participantEls = vm.$el.querySelectorAll('.js-participants-author');

          expect(participantEls.length).toBe(PARTICIPANT_LIST.length);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not have more participants link when they can all be shown', () => {
      const numberOfLessParticipants = 100;
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants,
      });
      const moreParticipantLink = vm.$el.querySelector('.js-toggle-participants-button');

      expect(PARTICIPANT_LIST.length).toBeLessThan(numberOfLessParticipants);
      expect(moreParticipantLink).toBeNull();
    });

    it('when too many participants, has more participants link to show more', (done) => {
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });
      vm.isShowingMoreParticipants = false;

      Vue.nextTick()
        .then(() => {
          const moreParticipantLink = vm.$el.querySelector('.js-toggle-participants-button');

          expect(moreParticipantLink.textContent.trim()).toBe('+ 1 more');
        })
        .then(done)
        .catch(done.fail);
    });

    it('when too many participants and already showing them, has more participants link to show less', (done) => {
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });
      vm.isShowingMoreParticipants = true;

      Vue.nextTick()
        .then(() => {
          const moreParticipantLink = vm.$el.querySelector('.js-toggle-participants-button');

          expect(moreParticipantLink.textContent.trim()).toBe('- show less');
        })
        .then(done)
        .catch(done.fail);
    });

    it('clicking more participants link emits event', () => {
      vm = mountComponent(Participants, {
        loading: false,
        participants: PARTICIPANT_LIST,
        numberOfLessParticipants: 2,
      });
      const moreParticipantLink = vm.$el.querySelector('.js-toggle-participants-button');

      expect(vm.isShowingMoreParticipants).toBe(false);

      moreParticipantLink.click();

      expect(vm.isShowingMoreParticipants).toBe(true);
    });
  });
});
