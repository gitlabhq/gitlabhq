import Vue from 'vue';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import groupItemComponent from '~/groups/components/group_item.vue';
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

    it('should render group and its subgroup', () => {
      const lists = component.$el.querySelectorAll('.group-list-tree');

      expect(lists.length).toBe(3); // one parent and two subgroups

      expect(lists[0].querySelector('#group-1119').classList.contains('is-open')).toBe(true);
      expect(lists[0].querySelector('#group-1119').classList.contains('has-subgroups')).toBe(true);

      expect(lists[2].querySelector('#group-1120').textContent).toContain(groups[1119].subGroups[1120].name);
    });

    it('should remove prefix of parent group', () => {
      expect(component.$el.querySelector('#group-12 #group-1128 .title').textContent).toContain('level2 / level3 / level4');
    });
  });
});
