import Vue from 'vue';
import VueResource from 'vue-resource';

import GroupsService from '~/groups/service/groups_service';
import { mockEndpoint, mockParentGroupItem } from '../mock_data';

Vue.use(VueResource);

describe('GroupsService', () => {
  let service;

  beforeEach(() => {
    service = new GroupsService(mockEndpoint);
  });

  describe('getGroups', () => {
    it('should return promise for `GET` request on provided endpoint', () => {
      spyOn(service.groups, 'get').and.stub();
      const queryParams = {
        page: 2,
        filter: 'git',
        sort: 'created_asc',
        archived: true,
      };

      service.getGroups(55, 2, 'git', 'created_asc', true);
      expect(service.groups.get).toHaveBeenCalledWith({ parent_id: 55 });

      service.getGroups(null, 2, 'git', 'created_asc', true);
      expect(service.groups.get).toHaveBeenCalledWith(queryParams);
    });
  });

  describe('leaveGroup', () => {
    it('should return promise for `DELETE` request on provided endpoint', () => {
      spyOn(Vue.http, 'delete').and.stub();

      service.leaveGroup(mockParentGroupItem.leavePath);
      expect(Vue.http.delete).toHaveBeenCalledWith(mockParentGroupItem.leavePath);
    });
  });
});
