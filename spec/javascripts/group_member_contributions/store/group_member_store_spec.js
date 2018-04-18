import GroupMemberStore from 'ee/group_member_contributions/store/group_member_store';
import defaultColumns from 'ee/group_member_contributions/constants';

import { rawMembers } from '../mock_data';

describe('GroupMemberStore', () => {
  let store;

  beforeEach(() => {
    store = new GroupMemberStore();
  });

  describe('setColumns', () => {
    beforeEach(() => {
      store.setColumns(defaultColumns);
    });

    it('sets columns to store state', () => {
      expect(store.state.columns).toBe(defaultColumns);
    });

    it('initializes sortOrders on store state', () => {
      Object.keys(store.state.sortOrders).forEach(column => {
        expect(store.state.sortOrders[column]).toBe(1);
      });
    });
  });

  describe('setMembers', () => {
    it('sets members to store state', () => {
      store.setMembers(rawMembers);
      expect(store.state.members.length).toBe(rawMembers.length);
    });
  });

  describe('sortMembers', () => {
    it('sorts members list based on provided column name', () => {
      store.setColumns(defaultColumns);
      store.setMembers(rawMembers);

      let firstMember = store.state.members[0];
      expect(firstMember.fullname).toBe('Administrator');

      store.sortMembers('fullname');
      firstMember = store.state.members[0];
      expect(firstMember.fullname).toBe('Terrell Graham');
    });
  });
});
