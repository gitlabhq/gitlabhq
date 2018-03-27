import GroupsStore from '~/groups/store/groups_store';
import {
  mockGroups, mockSearchedGroups,
  mockParentGroupItem, mockRawChildren,
  mockRawPageInfo,
} from '../mock_data';

describe('ProjectsStore', () => {
  describe('constructor', () => {
    it('should initialize default state', () => {
      let store;

      store = new GroupsStore();
      expect(Object.keys(store.state).length).toBe(2);
      expect(Array.isArray(store.state.groups)).toBeTruthy();
      expect(Object.keys(store.state.pageInfo).length).toBe(0);
      expect(store.hideProjects).not.toBeDefined();

      store = new GroupsStore(true);
      expect(store.hideProjects).toBeTruthy();
    });
  });

  describe('setGroups', () => {
    it('should set groups to state', () => {
      const store = new GroupsStore();
      spyOn(store, 'formatGroupItem').and.callThrough();

      store.setGroups(mockGroups);
      expect(store.state.groups.length).toBe(mockGroups.length);
      expect(store.formatGroupItem).toHaveBeenCalledWith(jasmine.any(Object));
      expect(Object.keys(store.state.groups[0]).indexOf('fullName') > -1).toBeTruthy();
    });
  });

  describe('setSearchedGroups', () => {
    it('should set searched groups to state', () => {
      const store = new GroupsStore();
      spyOn(store, 'formatGroupItem').and.callThrough();

      store.setSearchedGroups(mockSearchedGroups);
      expect(store.state.groups.length).toBe(mockSearchedGroups.length);
      expect(store.formatGroupItem).toHaveBeenCalledWith(jasmine.any(Object));
      expect(Object.keys(store.state.groups[0]).indexOf('fullName') > -1).toBeTruthy();
      expect(Object.keys(store.state.groups[0].children[0]).indexOf('fullName') > -1).toBeTruthy();
    });
  });

  describe('setGroupChildren', () => {
    it('should set children to group item in state', () => {
      const store = new GroupsStore();
      spyOn(store, 'formatGroupItem').and.callThrough();

      store.setGroupChildren(mockParentGroupItem, mockRawChildren);
      expect(store.formatGroupItem).toHaveBeenCalledWith(jasmine.any(Object));
      expect(mockParentGroupItem.children.length).toBe(1);
      expect(Object.keys(mockParentGroupItem.children[0]).indexOf('fullName') > -1).toBeTruthy();
      expect(mockParentGroupItem.isOpen).toBeTruthy();
      expect(mockParentGroupItem.isChildrenLoading).toBeFalsy();
    });
  });

  describe('setPaginationInfo', () => {
    it('should parse and set pagination info in state', () => {
      const store = new GroupsStore();

      store.setPaginationInfo(mockRawPageInfo);
      expect(store.state.pageInfo.perPage).toBe(10);
      expect(store.state.pageInfo.page).toBe(10);
      expect(store.state.pageInfo.total).toBe(10);
      expect(store.state.pageInfo.totalPages).toBe(10);
      expect(store.state.pageInfo.nextPage).toBe(10);
      expect(store.state.pageInfo.previousPage).toBe(10);
    });
  });

  describe('formatGroupItem', () => {
    it('should parse group item object and return updated object', () => {
      let store;
      let updatedGroupItem;

      store = new GroupsStore();
      updatedGroupItem = store.formatGroupItem(mockRawChildren[0]);
      expect(Object.keys(updatedGroupItem).indexOf('fullName') > -1).toBeTruthy();
      expect(updatedGroupItem.childrenCount).toBe(mockRawChildren[0].children_count);
      expect(updatedGroupItem.isChildrenLoading).toBe(false);
      expect(updatedGroupItem.isBeingRemoved).toBe(false);

      store = new GroupsStore(true);
      updatedGroupItem = store.formatGroupItem(mockRawChildren[0]);
      expect(Object.keys(updatedGroupItem).indexOf('fullName') > -1).toBeTruthy();
      expect(updatedGroupItem.childrenCount).toBe(mockRawChildren[0].subgroup_count);
    });
  });

  describe('removeGroup', () => {
    it('should remove children from group item in state', () => {
      const store = new GroupsStore();
      const rawParentGroup = Object.assign({}, mockGroups[0]);
      const rawChildGroup = Object.assign({}, mockGroups[1]);

      store.setGroups([rawParentGroup]);
      store.setGroupChildren(store.state.groups[0], [rawChildGroup]);
      const childItem = store.state.groups[0].children[0];

      store.removeGroup(childItem, store.state.groups[0]);
      expect(store.state.groups[0].children.length).toBe(0);
    });
  });
});
