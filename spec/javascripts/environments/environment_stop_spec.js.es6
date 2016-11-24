//= require vue
//= require environments/components/environment_stop
describe('Stop Component', () => {
  fixture.preload('environments/element.html');

  let stopURL;
  let component;

  beforeEach(() => {
    fixture.load('environments/element.html');

    stopURL = '/stop';
    component = new window.gl.environmentsList.StopComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        stop_url: stopURL,
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
