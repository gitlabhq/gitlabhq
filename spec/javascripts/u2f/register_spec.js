import $ from 'jquery';
import U2FRegister from '~/u2f/register';
import 'vendor/u2f';
import MockU2FDevice from './mock_u2f_device';

describe('U2FRegister', function () {
  preloadFixtures('u2f/register.html.raw');

  beforeEach((done) => {
    loadFixtures('u2f/register.html.raw');
    this.u2fDevice = new MockU2FDevice();
    this.container = $('#js-register-u2f');
    this.component = new U2FRegister(this.container, $('#js-register-u2f-templates'), {}, 'token');
    this.component.start().then(done).catch(done.fail);
  });

  it('allows registering a U2F device', () => {
    const setupButton = this.container.find('#js-setup-u2f-device');
    expect(setupButton.text()).toBe('Setup new U2F device');
    setupButton.trigger('click');
    const inProgressMessage = this.container.children('p');
    expect(inProgressMessage.text()).toContain('Trying to communicate with your device');
    this.u2fDevice.respondToRegisterRequest({
      deviceData: 'this is data from the device',
    });
    const registeredMessage = this.container.find('p');
    const deviceResponse = this.container.find('#js-device-response');
    expect(registeredMessage.text()).toContain('Your device was successfully set up!');
    return expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}');
  });

  return describe('errors', () => {
    it('doesn\'t allow the same device to be registered twice (for the same user', () => {
      const setupButton = this.container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        errorCode: 4,
      });
      const errorMessage = this.container.find('p');
      return expect(errorMessage.text()).toContain('already been registered with us');
    });

    it('displays an error message for other errors', () => {
      const setupButton = this.container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        errorCode: 'error!',
      });
      const errorMessage = this.container.find('p');
      return expect(errorMessage.text()).toContain('There was a problem communicating with your device');
    });

    return it('allows retrying registration after an error', () => {
      let setupButton = this.container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        errorCode: 'error!',
      });
      const retryButton = this.container.find('#U2FTryAgain');
      retryButton.trigger('click');
      setupButton = this.container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        deviceData: 'this is data from the device',
      });
      const registeredMessage = this.container.find('p');
      return expect(registeredMessage.text()).toContain('Your device was successfully set up!');
    });
  });
});
