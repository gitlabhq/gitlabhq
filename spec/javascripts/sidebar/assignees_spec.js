import Vue from 'vue';
import Assignee from '~/sidebar/components/assignees/assignees.vue';
import UsersMock from './mock_data';
import UsersMockHelper from '../helpers/user_mock_data_helper';

describe('Assignee component', () => {
  let component;
  let AssigneeComponent;

  beforeEach(() => {
    AssigneeComponent = Vue.extend(Assignee);
  });

  describe('No assignees/users', () => {
    it('displays no assignee icon when collapsed', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: false,
        },
      }).$mount();

      const collapsed = component.$el.querySelector('.sidebar-collapsed-icon');

      expect(collapsed.childElementCount).toEqual(1);
      expect(collapsed.children[0].getAttribute('aria-label')).toEqual('None');
      expect(collapsed.children[0].classList.contains('fa')).toEqual(true);
      expect(collapsed.children[0].classList.contains('fa-user')).toEqual(true);
    });

    it('displays only "None" when no users are assigned and the issue is read-only', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: false,
        },
      }).$mount();
      const componentTextNoUsers = component.$el.querySelector('.assign-yourself').innerText.trim();

      expect(componentTextNoUsers).toBe('None');
      expect(componentTextNoUsers.indexOf('assign yourself')).toEqual(-1);
    });

    it('displays only "None" when no users are assigned and the issue can be edited', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: true,
        },
      }).$mount();
      const componentTextNoUsers = component.$el.querySelector('.assign-yourself').innerText.trim();

      expect(componentTextNoUsers.indexOf('None')).toEqual(0);
      expect(componentTextNoUsers.indexOf('assign yourself')).toBeGreaterThan(0);
    });

    it('emits the assign-self event when "assign yourself" is clicked', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [],
          editable: true,
        },
      }).$mount();

      spyOn(component, '$emit');
      component.$el.querySelector('.assign-yourself .btn-link').click();

      expect(component.$emit).toHaveBeenCalledWith('assign-self');
    });
  });

  describe('One assignee/user', () => {
    it('displays one assignee icon when collapsed', () => {
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users: [UsersMock.user],
          editable: false,
        },
      }).$mount();

      const collapsed = component.$el.querySelector('.sidebar-collapsed-icon');
      const assignee = collapsed.children[0];

      expect(collapsed.childElementCount).toEqual(1);
      expect(assignee.querySelector('.avatar').getAttribute('src')).toEqual(UsersMock.user.avatar);
      expect(assignee.querySelector('.avatar').getAttribute('alt')).toEqual(
        `${UsersMock.user.name}'s avatar`,
      );

      expect(assignee.querySelector('.author').innerText.trim()).toEqual(UsersMock.user.name);
    });
  });

  describe('Two or more assignees/users', () => {
    it('has no "cannot merge" tooltip when every user can merge', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      users[0].can_merge = true;
      users[1].can_merge = true;

      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000/',
          users,
          editable: true,
          issuableType: 'merge_request',
        },
      }).$mount();

      expect(component.collapsedTooltipTitle).not.toContain('cannot merge');
    });

    it('displays two assignee icons when collapsed', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: false,
        },
      }).$mount();

      const collapsed = component.$el.querySelector('.sidebar-collapsed-icon');

      expect(collapsed.childElementCount).toEqual(2);

      const first = collapsed.children[0];

      expect(first.querySelector('.avatar').getAttribute('src')).toEqual(users[0].avatar);
      expect(first.querySelector('.avatar').getAttribute('alt')).toEqual(
        `${users[0].name}'s avatar`,
      );

      expect(first.querySelector('.author').innerText.trim()).toEqual(users[0].name);

      const second = collapsed.children[1];

      expect(second.querySelector('.avatar').getAttribute('src')).toEqual(users[1].avatar);
      expect(second.querySelector('.avatar').getAttribute('alt')).toEqual(
        `${users[1].name}'s avatar`,
      );

      expect(second.querySelector('.author').innerText.trim()).toEqual(users[1].name);
    });

    it('displays one assignee icon and counter when collapsed', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: false,
        },
      }).$mount();

      const collapsed = component.$el.querySelector('.sidebar-collapsed-icon');

      expect(collapsed.childElementCount).toEqual(2);

      const first = collapsed.children[0];

      expect(first.querySelector('.avatar').getAttribute('src')).toEqual(users[0].avatar);
      expect(first.querySelector('.avatar').getAttribute('alt')).toEqual(
        `${users[0].name}'s avatar`,
      );

      expect(first.querySelector('.author').innerText.trim()).toEqual(users[0].name);

      const second = collapsed.children[1];

      expect(second.querySelector('.avatar-counter').innerText.trim()).toEqual('+2');
    });

    it('Shows two assignees', () => {
      const users = UsersMockHelper.createNumberRandomUsers(2);
      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: true,
        },
      }).$mount();

      expect(component.$el.querySelectorAll('.user-item').length).toEqual(users.length);
      expect(component.$el.querySelector('.user-list-more')).toBe(null);
    });

    it('shows sorted assignee where "can merge" users are sorted first', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: true,
        },
      }).$mount();

      expect(component.sortedAssigness[0].can_merge).toBe(true);
    });

    it('passes the sorted assignees to the uncollapsed-assignee-list', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: false,
        },
      }).$mount();

      const userItems = component.$el.querySelectorAll('.user-list .user-item a');

      expect(userItems.length).toBe(3);
      expect(userItems[0].dataset.originalTitle).toBe(users[2].name);
    });

    it('passes the sorted assignees to the collapsed-assignee-list', () => {
      const users = UsersMockHelper.createNumberRandomUsers(3);
      users[0].can_merge = false;
      users[1].can_merge = false;
      users[2].can_merge = true;

      component = new AssigneeComponent({
        propsData: {
          rootPath: 'http://localhost:3000',
          users,
          editable: false,
        },
      }).$mount();

      const collapsedButton = component.$el.querySelector('.sidebar-collapsed-user button');

      expect(collapsedButton.innerText.trim()).toBe(users[2].name);
    });
  });
});
