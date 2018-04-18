import axios from '~/lib/utils/axios_utils';

import GroupMemberService from 'ee/group_member_contributions/service/group_member_service';

import { contributionsPath } from '../mock_data';

describe('GroupMemberService', () => {
  let service;

  beforeEach(() => {
    service = new GroupMemberService(contributionsPath);
  });

  describe('constructor', () => {
    it('initializes default properties', () => {
      expect(service.memberContributionsPath).toBe(contributionsPath);
    });
  });

  describe('getContributedMembers', () => {
    it('returns axios instance for memberContributionsPath', () => {
      spyOn(axios, 'get').and.stub();
      service.getContributedMembers();
      expect(axios.get).toHaveBeenCalledWith(service.memberContributionsPath);
    });
  });
});
