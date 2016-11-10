//= require vue
//= require environments/components/environment_stop
describe('Stop Component', () => {
  fixture.preload('environments/element.html');
  beforeEach(() => {
    fixture.load('environments/element.html');
  });

  it('should link to the provided URL', () => {
    const stopURL = 'https://gitlab.com/stop';
    const component = new window.gl.environmentsList.StopComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        stop_url: stopURL,
      },
    });
    expect(component.$el.getAttribute('href')).toEqual(stopURL);
  });

  describe('When clicked', () => {
    it('Should open popup with confirmation warning', () => {
      const component = new window.gl.environmentsList.StopComponent({
        el: document.querySelector('.test-dom-element'),
        propsData: {
          stop_url: '#',
        },
      });

      const spy = spyOn(window, 'confirm');
      component.$el.click();
      expect(spy).toHaveBeenCalled();
    });
  });
});
