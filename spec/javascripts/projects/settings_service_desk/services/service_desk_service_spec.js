import ServiceDeskService from '~/projects/settings_service_desk/services/service_desk_service';

describe('ServiceDeskService', () => {
  let service;

  beforeEach(() => {
    service = new ServiceDeskService('');
  });

  it('fetchIncomingEmail', (done) => {
    spyOn(service.serviceDeskResource, 'get').and.returnValue(Promise.resolve({
      data: {
        service_desk_enabled: true,
        service_desk_address: 'foo@bar.com',
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

  describe('toggleServiceDesk', () => {
    it('enable Service Desk', (done) => {
      spyOn(service.serviceDeskResource, 'update').and.returnValue(Promise.resolve({
        data: {
          service_desk_enabled: true,
          service_desk_address: 'foo@bar.com',
        },
      }));

      service.toggleServiceDesk(true)
        .then((incomingEmail) => {
          expect(incomingEmail).toEqual('foo@bar.com');
          done();
        })
        .catch((err) => {
          done.fail(`Failed to enable Service Desk and fetch incoming email:\n${err}`);
        });
    });

    it('disable Service Desk', (done) => {
      spyOn(service.serviceDeskResource, 'update').and.returnValue(Promise.resolve({
        data: {
          service_desk_enabled: false,
          service_desk_address: null,
        },
      }));

      service.toggleServiceDesk(false)
        .then((incomingEmail) => {
          expect(incomingEmail).toEqual(null);
          done();
        })
        .catch((err) => {
          done.fail(`Failed to disable Service Desk and reset incoming email:\n${err}`);
        });
    });
  });
});
