import Vue from 'vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import GroupsStore from '~/groups/stores/groups_store';
import { group1 } from './mock_data';

describe('Groups Component', () => {
  let GroupItemComponent;
  let component;
  let store;
  let group;

  describe('group with default data', () => {
    beforeEach((done) => {
      GroupItemComponent = Vue.extend(groupItemComponent);
      store = new GroupsStore();
      group = store.decorateGroup(group1);

      component = new GroupItemComponent({
        propsData: {
          group,
        },
      }).$mount();

      Vue.nextTick(() => {
        done();
      });
    });

    afterEach(() => {
      component.$destroy();
    });

    it('should render the group item correctly', () => {
      expect(component.$el.classList.contains('group-row')).toBe(true);
      expect(component.$el.classList.contains('.no-description')).toBe(false);
      expect(component.$el.querySelector('.number-projects').textContent).toContain(group.numberProjects);
      expect(component.$el.querySelector('.number-users').textContent).toContain(group.numberUsers);
      expect(component.$el.querySelector('.group-visibility')).toBeDefined();
      expect(component.$el.querySelector('.avatar-container')).toBeDefined();
      expect(component.$el.querySelector('.title').textContent).toContain(group.name);
      expect(component.$el.querySelector('.access-type').textContent).toContain(group.permissions.humanGroupAccess);
      expect(component.$el.querySelector('.description').textContent).toContain(group.description);
      expect(component.$el.querySelector('.edit-group')).toBeDefined();
      expect(component.$el.querySelector('.leave-group')).toBeDefined();
    });
  });

  describe('group without description', () => {
    beforeEach((done) => {
      GroupItemComponent = Vue.extend(groupItemComponent);
      store = new GroupsStore();
      group1.description = '';
      group = store.decorateGroup(group1);

      component = new GroupItemComponent({
        propsData: {
          group,
        },
      }).$mount();

      Vue.nextTick(() => {
        done();
      });
    });

    afterEach(() => {
      component.$destroy();
    });

    it('should render group item correctly', () => {
      expect(component.$el.querySelector('.description').textContent).toBe('');
      expect(component.$el.classList.contains('.no-description')).toBe(false);
    });
  });

  describe('user has not access to group', () => {
    beforeEach((done) => {
      GroupItemComponent = Vue.extend(groupItemComponent);
      store = new GroupsStore();
      group1.permissions.human_group_access = null;
      group = store.decorateGroup(group1);

      component = new GroupItemComponent({
        propsData: {
          group,
        },
      }).$mount();

      Vue.nextTick(() => {
        done();
      });
    });

    afterEach(() => {
      component.$destroy();
    });

    it('should not display access type', () => {
      expect(component.$el.querySelector('.access-type')).toBeNull();
    });
  });
});
