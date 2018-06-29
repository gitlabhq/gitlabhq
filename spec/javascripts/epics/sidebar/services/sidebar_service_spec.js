import axios from '~/lib/utils/axios_utils';

import SidebarService from 'ee/epics/sidebar/services/sidebar_service';

describe('Sidebar Service', () => {
  let service;

  beforeEach(() => {
    service = new SidebarService({
      endpoint: gl.TEST_HOST,
      subscriptionEndpoint: gl.TEST_HOST,
      todoPath: gl.TEST_HOST,
    });
  });

  describe('updateStartDate', () => {
    it('returns axios instance with PUT for `endpoint` and `start_date` as request body', () => {
      spyOn(axios, 'put').and.stub();
      const startDate = '2018-06-21';
      service.updateStartDate(startDate);
      expect(axios.put).toHaveBeenCalledWith(service.endpoint, {
        start_date: startDate,
      });
    });
  });

  describe('updateEndDate', () => {
    it('returns axios instance with PUT for `endpoint` and `end_date` as request body', () => {
      spyOn(axios, 'put').and.stub();
      const endDate = '2018-06-21';
      service.updateEndDate(endDate);
      expect(axios.put).toHaveBeenCalledWith(service.endpoint, {
        end_date: endDate,
      });
    });
  });

  describe('toggleSubscribed', () => {
    it('returns axios instance with POST for `subscriptionEndpoint`', () => {
      spyOn(axios, 'post').and.stub();
      service.toggleSubscribed();
      expect(axios.post).toHaveBeenCalled();
    });
  });

  describe('addTodo', () => {
    it('returns axios instance with POST for `todoPath` with `issuable_id` and `issuable_type` as request body', () => {
      spyOn(axios, 'post').and.stub();
      const epicId = 1;
      service.addTodo(epicId);
      expect(axios.post).toHaveBeenCalledWith(service.todoPath, {
        issuable_id: epicId,
        issuable_type: 'epic',
      });
    });
  });

  describe('deleteTodo', () => {
    it('returns axios instance with DELETE for provided `todoDeletePath` param', () => {
      spyOn(axios, 'delete').and.stub();
      service.deleteTodo('/foo/bar');
      expect(axios.delete).toHaveBeenCalledWith('/foo/bar');
    });
  });
});
