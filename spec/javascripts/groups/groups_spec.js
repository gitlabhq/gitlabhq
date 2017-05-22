import Vue from 'vue';
import GroupFolder from '~/groups/components/group_folder.vue';
import GroupItem from '~/groups/components/group_item.vue';
import groupsComponent from '~/groups/components/groups.vue';
import GroupsStore from '~/groups/stores/groups_store';
import groupsData from './mock_data';

describe('Groups', () => {
  let GroupsComponent;
  let store;

  beforeEach(() => {
    Vue.component('group-folder', GroupFolder);
    Vue.component('group-item', GroupItem);

    store = new GroupsStore();
    store.setGroups(groupsData.groups);
    store.storePagination(groupsData.pagination);

    GroupsComponent = Vue.extend(groupsComponent);
  });

  describe('with data', () => {
    it('should render a list of groups', (done) => {
      const component = new GroupsComponent({
        propsData: {
          groups: store.state.groups,
          pageInfo: store.state.pageInfo,
        },
      }).$mount();

      setTimeout(() => {
        expect(component.$el.classList.contains('groups-list-tree-container')).toBe(true);
        done();
      });
    });
  });
});
