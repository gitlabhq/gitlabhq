import Vue from 'vue';
import eventHub from '~/groups/event_hub';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import groupIdenticonComponent from '~/groups/components/group_identicon.vue';
import groupsComponent from '~/groups/components/groups.vue';
import GroupsStore from '~/groups/stores/groups_store';
import { groupsData } from './mock_data';

describe('Groups Component', () => {
  let GroupsComponent;
  let store;
  let component;
  let groups;

  beforeEach((done) => {
    Vue.component('group-folder', groupFolderComponent);
    Vue.component('group-identicon', groupIdenticonComponent);
    Vue.component('group-item', groupItemComponent);

    store = new GroupsStore();
    groups = store.setGroups(groupsData.groups);

    store.storePagination(groupsData.pagination);

    GroupsComponent = Vue.extend(groupsComponent);

    component = new GroupsComponent({
      propsData: {
        groups: store.state.groups,
        pageInfo: store.state.pageInfo,
      },
    }).$mount();

    Vue.nextTick(() => {
      done();
    });
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('with data', () => {
    it('should render a list of groups', () => {
      expect(component.$el.classList.contains('groups-list-tree-container')).toBe(true);
      expect(component.$el.querySelector('#group-12')).toBeDefined();
      expect(component.$el.querySelector('#group-1119')).toBeDefined();
      expect(component.$el.querySelector('#group-1120')).toBeDefined();
    });

    it('should respect the order of groups', () => {
      const wrap = component.$el.querySelector('.groups-list-tree-container > .group-list-tree');
      expect(wrap.querySelector('.group-row:nth-child(1)').id).toBe('group-12');
      expect(wrap.querySelector('.group-row:nth-child(2)').id).toBe('group-1119');
    });

    it('should render group and its subgroup', () => {
      const lists = component.$el.querySelectorAll('.group-list-tree');

      expect(lists.length).toBe(3); // one parent and two subgroups

      expect(lists[0].querySelector('#group-1119').classList.contains('is-open')).toBe(true);
      expect(lists[0].querySelector('#group-1119').classList.contains('has-subgroups')).toBe(true);

      expect(lists[2].querySelector('#group-1120').textContent).toContain(groups.id1119.subGroups.id1120.name);
    });

    it('should render group identicon when group avatar is not present', () => {
      const avatar = component.$el.querySelector('#group-12 .avatar-container .avatar');
      expect(avatar.nodeName).toBe('DIV');
      expect(avatar.classList.contains('identicon')).toBeTruthy();
      expect(avatar.getAttribute('style').indexOf('background-color') > -1).toBeTruthy();
    });

    it('should render group avatar when group avatar is present', () => {
      const avatar = component.$el.querySelector('#group-1120 .avatar-container .avatar');
      expect(avatar.nodeName).toBe('IMG');
      expect(avatar.classList.contains('identicon')).toBeFalsy();
    });

    it('should remove prefix of parent group', () => {
      expect(component.$el.querySelector('#group-12 #group-1128 .title').textContent).toContain('level2 / level3 / level4');
    });

    it('should remove the group after leaving the group', (done) => {
      spyOn(window, 'confirm').and.returnValue(true);

      eventHub.$on('leaveGroup', (group, collection) => {
        store.removeGroup(group, collection);
      });

      component.$el.querySelector('#group-12 .leave-group').click();

      Vue.nextTick(() => {
        expect(component.$el.querySelector('#group-12')).toBeNull();
        done();
      });
    });
  });
});
