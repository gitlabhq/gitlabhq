import Service from '~/deploy_keys/services/deploy_keys_service';

describe('DeployKeysService', () => {
  let service;

  beforeEach(() => {
    service = new Service('endpoint');
  });

  it('should set endpoint', () => {
    expect(service.endpoint).toBeDefined();
  });

  it('should get from endpoint', () => {
    spyOn(service.endpoint, 'get').and.callFake(() => {});

    service.get();
    expect(service.endpoint.get).toHaveBeenCalled();
  });

});
