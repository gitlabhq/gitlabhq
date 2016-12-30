//= require vue
//= require environments/components/environment_external_url

describe('External URL Component', () => {
  fixture.preload('static/environments/element.html.raw');
  beforeEach(() => {
    fixture.load('static/environments/element.html.raw');
  });

  it('should link to the provided externalUrl prop', () => {
    const externalURL = 'https://gitlab.com';
    const component = new window.gl.environmentsList.ExternalUrlComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        externalUrl: externalURL,
      },
    });

    expect(component.$el.getAttribute('href')).toEqual(externalURL);
    expect(component.$el.querySelector('fa-external-link')).toBeDefined();
  });
});
