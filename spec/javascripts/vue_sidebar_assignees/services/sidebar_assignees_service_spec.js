import SidebarAssigneesService from '~/vue_sidebar_assignees/services/sidebar_assignees_service';

describe('SidebarAssigneesService', () => {
  let service;

  beforeEach(() => {
    service = new SidebarAssigneesService('', 'field');
  });

  describe('constructor', () => {
    it('should save field', () => {
      expect(service.field).toEqual('field');
    });

    it('should save sidebarAssigneeResource', () => {
      expect(service.sidebarAssigneeResource).toBeDefined();
    });
  });

  describe('update', () => {
    it('should call vue resource update', (done) => {
      const userIds = [1, 2, 3];

      spyOn(service.sidebarAssigneeResource, 'update').and.callFake((o) => {
        expect(o.field).toEqual(userIds);
        done();
      });

      service.update(userIds);
    });
  });
});
