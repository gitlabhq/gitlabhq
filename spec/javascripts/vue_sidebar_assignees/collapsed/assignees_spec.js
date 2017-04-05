import Vue from 'vue';
import assigneesComponent from '~/vue_sidebar_assignees/components/collapsed/assignees';
import avatarComponent from '~/vue_sidebar_assignees/components/collapsed/avatar';
import VueSpecHelper from '../../helpers/vue_spec_helper';
import { mockUser, mockUser2, mockUser3 } from '../mock_data';

describe('CollapsedAssignees', () => {
  const mockUsers = [mockUser, mockUser2];

  const createAssigneesComponent = props =>
    VueSpecHelper.createComponent(Vue, assigneesComponent, props);

  const createAvatarComponent = props =>
    VueSpecHelper.createComponent(Vue, avatarComponent, props);

  describe('computed', () => {
    describe('title', () => {
      it('returns one name when there is one assignee', () => {
        const users = Object.assign([], mockUsers);
        users.pop();

        const vm = createAssigneesComponent({
          users,
        });

        expect(vm.title).toEqual('Clark Kent');
      });

      it('returns two names when there are two assignees', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
        });

        expect(vm.title).toEqual('Clark Kent, Bruce Wayne');
      });

      it('returns more text when there are more than defaultRenderCount assignees', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
          defaultRenderCount: 1,
        });

        expect(vm.title).toEqual('Clark Kent, + 1 more');
      });
    });

    describe('counter', () => {
      it('should return one less than users.length', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
        });

        expect(vm.counter).toEqual('+1');
      });

      it('should return defaultMaxCounter+ when users.length is greater than defaultMaxCounter', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
          defaultMaxCounter: 1,
        });

        expect(vm.counter).toEqual('1+');
      });
    });

    describe('hasNoAssignees', () => {
      it('returns true when there are no assignees', () => {
        const vm = createAssigneesComponent({
          users: [],
        });

        expect(vm.hasNoAssignees).toEqual(true);
      });

      it('returns false when there are assignees', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
        });

        expect(vm.hasNoAssignees).toEqual(false);
      });
    });

    describe('hasTwoAssignees', () => {
      it('returns true when there are two assignees', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
        });

        expect(vm.hasTwoAssignees).toEqual(true);
      });

      it('returns false when there is no assignes', () => {
        const vm = createAssigneesComponent({
          users: [],
        });

        expect(vm.hasTwoAssignees).toEqual(false);
      });
    });

    describe('moreThanOneAssignees', () => {
      it('returns true when there are more than one assignee', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
        });

        expect(vm.moreThanOneAssignees).toEqual(true);
      });

      it('returns false when there is one assignee', () => {
        const users = Object.assign([], mockUsers);
        users.pop();

        const vm = createAssigneesComponent({
          users,
        });

        expect(vm.moreThanOneAssignees).toEqual(false);
      });
    });

    describe('moreThanTwoAssignees', () => {
      it('returns true when there are more than two assignees', () => {
        const users = Object.assign([], mockUsers);
        users.push(mockUser3);

        const vm = createAssigneesComponent({
          users,
        });

        expect(vm.moreThanTwoAssignees).toEqual(true);
      });

      it('returns false when there are two assignees', () => {
        const vm = createAssigneesComponent({
          users: mockUsers,
        });

        expect(vm.moreThanTwoAssignees).toEqual(false);
      });
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(assigneesComponent.components['collapsed-avatar']).toBeDefined();
    });
  });

  describe('template', () => {
    function avatarProp(user) {
      return {
        name: user.name,
        avatarUrl: user.avatarUrl,
      };
    }

    it('should render fa-user if there are no assignees', () => {
      const el = createAssigneesComponent({
        users: [],
      }).$el;

      const sidebarCollapsedIcons = el.querySelectorAll('.sidebar-collapsed-icon');
      expect(sidebarCollapsedIcons.length).toEqual(1);

      const userIcon = sidebarCollapsedIcons[0].querySelector('.fa-user');
      expect(userIcon).toBeDefined();
    });

    it('should not render fa-user if there are assignees', () => {
      const el = createAssigneesComponent({
        users: mockUsers,
      }).$el;

      const sidebarCollapsedIcons = el.querySelectorAll('.sidebar-collapsed-icon');
      expect(sidebarCollapsedIcons.length).toEqual(1);

      const userIcon = sidebarCollapsedIcons[0].querySelector('.fa-user');
      expect(userIcon).toBeNull();
    });

    it('should render one assignee if there is one assignee', () => {
      const users = Object.assign([], mockUsers);
      users.pop();

      const vm = createAssigneesComponent({
        users,
      });
      const el = vm.$el;

      const sidebarCollapsedIcons = el.querySelectorAll('.sidebar-collapsed-icon');
      expect(sidebarCollapsedIcons.length).toEqual(1);

      const div = sidebarCollapsedIcons[0];
      expect(div.getAttribute('data-original-title')).toEqual(vm.title);
      expect(div.classList.contains('multiple-users')).toEqual(false);

      expect(div.querySelector('.avatar-counter')).toBeNull();

      const avatarEl = createAvatarComponent(avatarProp(users[0])).$el;

      const divWithoutComments = div.innerHTML.replace(/<!---->/g, '').trim();
      expect(divWithoutComments).toEqual(avatarEl.outerHTML);
    });

    it('should render two assignees if there are two assignees', () => {
      const vm = createAssigneesComponent({
        users: mockUsers,
      });
      const el = vm.$el;

      const sidebarCollapsedIcons = el.querySelectorAll('.sidebar-collapsed-icon');
      expect(sidebarCollapsedIcons.length).toEqual(1);

      const div = sidebarCollapsedIcons[0];
      expect(div.getAttribute('data-original-title')).toEqual(vm.title);
      expect(div.classList.contains('multiple-users')).toEqual(true);

      expect(div.querySelector('.avatar-counter')).toBeNull();

      const avatarEl = [
        createAvatarComponent(avatarProp(mockUsers[0])).$el,
        createAvatarComponent(avatarProp(mockUsers[1])).$el,
      ];

      const divWithoutComments = div.innerHTML.replace(/<!---->/g, '').trim();
      expect(divWithoutComments).toEqual(`${avatarEl[0].outerHTML} ${avatarEl[1].outerHTML}`);
    });

    it('should render counter if there are more than two assignees', () => {
      const users = Object.assign([], mockUsers);
      users.push(mockUser3);

      const vm = createAssigneesComponent({
        users,
      });
      const el = vm.$el;

      const sidebarCollapsedIcons = el.querySelectorAll('.sidebar-collapsed-icon');
      expect(sidebarCollapsedIcons.length).toEqual(1);

      const div = sidebarCollapsedIcons[0];
      expect(div.getAttribute('data-original-title')).toEqual(vm.title);
      expect(div.classList.contains('multiple-users')).toEqual(true);

      const avatarCounter = div.querySelector('.avatar-counter');
      expect(avatarCounter).toBeDefined();
      expect(avatarCounter.textContent).toEqual(vm.counter);

      const avatarEl = createAvatarComponent(avatarProp(users[0])).$el;
      expect(div.innerHTML.indexOf(avatarEl.outerHTML) !== -1).toEqual(true);
    });
  });
});
