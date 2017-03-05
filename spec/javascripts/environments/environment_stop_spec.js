const StopComponent = require('~/environments/components/environment_stop');

describe('Stop Component', () => {
  preloadFixtures('static/environments/element.html.raw');

  let stopURL;
  let component;

  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');

    stopURL = '/stop';
    component = new StopComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        stopUrl: stopURL,
      },
    });
  });

  it('should link to the provided URL', () => {
    expect(component.$el.getAttribute('href')).toEqual(stopURL);
  });

  it('should have a data-confirm attribute', () => {
    expect(component.$el.getAttribute('data-confirm')).toEqual('Are you sure you want to stop this environment?');
  });
});
