import Vue from 'vue';
import singleAssigneeComponent from '~/vue_sidebar_assignees/components/expanded/single_assignee';
import VueSpecHelper from '../../helpers/vue_spec_helper';
import { mockUser, mockUser2 } from '../mock_data';

describe('SingleAssignee', () => {
  const mockStore = {
    users: [mockUser],
    rootPath: 'rootPath',
  };

  const createComponent = props =>
    VueSpecHelper.createComponent(Vue, singleAssigneeComponent, props);

  describe('computed', () => {
    describe('user', () => {
      it('should return first user', () => {
        const newMockStore = Object.assign({}, mockStore);
        newMockStore.users.push(mockUser2);

        const vm = createComponent({
          store: newMockStore,
        });

        expect(vm.user).toEqual(newMockStore.users[0]);
      });
    });

    describe('userUrl', () => {
      it('should return url', () => {
        const vm = createComponent({
          store: mockStore,
        });

        expect(vm.userUrl).toEqual(`${mockStore.rootPath}${mockStore.users[0].username}`);
      });
    });

    describe('username', () => {
      it('should return username', () => {
        const vm = createComponent({
          store: mockStore,
        });

        expect(vm.username).toEqual(`@${mockStore.users[0].username}`);
      });
    });

    describe('avatarAlt', () => {
      it('should return alt text', () => {
        const vm = createComponent({
          store: mockStore,
        });

        expect(vm.avatarAlt).toEqual(`${mockStore.users[0].name}'s avatar`);
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent({
        store: mockStore,
      });
      el = vm.$el;
    });

    it('should load the userUrl in href ', () => {
      const link = el.querySelector('a');
      expect(link.href).toEqual(`${window.location.origin}/${vm.userUrl}`);
    });

    it('should load the avatarAlt', () => {
      const img = el.querySelector('img');
      expect(img.alt).toEqual(vm.avatarAlt);
    });

    it('should load the avatar image', () => {
      const img = el.querySelector('img');
      expect(img.src).toEqual(vm.user.avatarUrl);
    });

    it('should load the user\'s name', () => {
      const name = el.querySelector('.author');
      expect(name.textContent).toEqual(vm.user.name);
    });

    it('should load the user\'s username', () => {
      const username = el.querySelector('.username');
      expect(username.textContent).toEqual(vm.username);
    });
  });
});
