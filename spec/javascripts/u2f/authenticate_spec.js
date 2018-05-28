import $ from 'jquery';
import U2FAuthenticate from '~/u2f/authenticate';
import 'vendor/u2f';
import MockU2FDevice from './mock_u2f_device';

describe('U2FAuthenticate', function () {
  preloadFixtures('u2f/authenticate.html.raw');

  beforeEach((done) => {
    loadFixtures('u2f/authenticate.html.raw');
    this.u2fDevice = new MockU2FDevice();
    this.container = $('#js-authenticate-u2f');
    this.component = new U2FAuthenticate(
      this.container,
      '#js-login-u2f-form',
      {
        sign_requests: [],
      },
      document.querySelector('#js-login-2fa-device'),
      document.querySelector('.js-2fa-form'),
    );

    // bypass automatic form submission within renderAuthenticated
    spyOn(this.component, 'renderAuthenticated').and.returnValue(true);

    this.component.start().then(done).catch(done.fail);
  });

  it('allows authenticating via a U2F device', () => {
    const inProgressMessage = this.container.find('p');
    expect(inProgressMessage.text()).toContain('Trying to communicate with your device');
    this.u2fDevice.respondToAuthenticateRequest({
      deviceData: 'this is data from the device',
    });
    expect(this.component.renderAuthenticated).toHaveBeenCalledWith('{"deviceData":"this is data from the device"}');
  });

  describe('errors', () => {
    it('displays an error message', () => {
      const setupButton = this.container.find('#js-login-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToAuthenticateRequest({
        errorCode: 'error!',
      });
      const errorMessage = this.container.find('p');
      return expect(errorMessage.text()).toContain('There was a problem communicating with your device');
    });
    return it('allows retrying authentication after an error', () => {
      let setupButton = this.container.find('#js-login-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToAuthenticateRequest({
        errorCode: 'error!',
      });
      const retryButton = this.container.find('#js-u2f-try-again');
      retryButton.trigger('click');
      setupButton = this.container.find('#js-login-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToAuthenticateRequest({
        deviceData: 'this is data from the device',
      });
      expect(this.component.renderAuthenticated).toHaveBeenCalledWith('{"deviceData":"this is data from the device"}');
    });
  });
});
