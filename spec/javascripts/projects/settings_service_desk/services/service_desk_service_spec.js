import ServiceDeskService from '~/projects/settings_service_desk/services/service_desk_service';

describe('ServiceDeskService', () => {
  let service;

  beforeEach(() => {
    service = new ServiceDeskService('');
  });

  it('fetchIncomingEmail', (done) => {
    spyOn(service.project, 'get').and.returnValue(Promise.resolve({
      data: {
        incomingEmail: 'foo@bar.com',
      },
    }));

    service.fetchIncomingEmail()
      .then((incomingEmail) => {
        expect(incomingEmail).toEqual('foo@bar.com');
        done();
      })
      .catch((err) => {
        done.fail(`Failed to fetch incoming email:\n${err}`);
      });
  });
});
