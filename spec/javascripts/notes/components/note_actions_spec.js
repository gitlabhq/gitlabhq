import Vue from 'vue';
import store from '~/notes/stores';
import noteActions from '~/notes/components/note_actions.vue';
import { userDataMock } from '../mock_data';

describe('issue_note_actions component', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(noteActions);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('user is logged in', () => {
    let props;

    beforeEach(() => {
      props = {
        accessLevel: 'Master',
        authorId: 26,
        canDelete: true,
        canEdit: true,
        canAwardEmoji: true,
        canReportAsAbuse: true,
        noteId: 539,
        reportAbusePath: '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26',
      };

      store.dispatch('setUserData', userDataMock);

      vm = new Component({
        store,
        propsData: props,
      }).$mount();
    });

    it('should render access level badge', () => {
      expect(vm.$el.querySelector('.note-role').textContent.trim()).toEqual(props.accessLevel);
    });

    it('should render emoji link', () => {
      expect(vm.$el.querySelector('.js-add-award')).toBeDefined();
    });

    describe('actions dropdown', () => {
      it('should be possible to edit the comment', () => {
        expect(vm.$el.querySelector('.js-note-edit')).toBeDefined();
      });

      it('should be possible to report as abuse', () => {
        expect(vm.$el.querySelector(`a[href="${props.reportAbusePath}"]`)).toBeDefined();
      });

      it('should be possible to delete comment', () => {
        expect(vm.$el.querySelector('.js-note-delete')).toBeDefined();
      });
    });
  });

  describe('user is not logged in', () => {
    let props;

    beforeEach(() => {
      store.dispatch('setUserData', {});
      props = {
        accessLevel: 'Master',
        authorId: 26,
        canDelete: false,
        canEdit: false,
        canAwardEmoji: false,
        canReportAsAbuse: false,
        noteId: 539,
        reportAbusePath: '/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26',
      };
      vm = new Component({
        store,
        propsData: props,
      }).$mount();
    });

    it('should not render emoji link', () => {
      expect(vm.$el.querySelector('.js-add-award')).toEqual(null);
    });

    it('should not render actions dropdown', () => {
      expect(vm.$el.querySelector('.more-actions')).toEqual(null);
    });
  });
});
