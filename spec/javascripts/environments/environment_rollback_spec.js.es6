//= require vue
//= require environments/components/environment_rollback
describe('Rollback Component', () => {
  fixture.preload('environments/element.html');

  const retryURL = 'https://gitlab.com/retry';

  beforeEach(() => {
    fixture.load('environments/element.html');
  });

  it('Should link to the provided retry_url', () => {
    const component = new window.gl.environmentsList.RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retry_url: retryURL,
        is_last_deployment: true,
      },
    });

    expect(component.$el.getAttribute('href')).toEqual(retryURL);
  });

  it('Should render Re-deploy label when is_last_deployment is true', () => {
    const component = new window.gl.environmentsList.RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retry_url: retryURL,
        is_last_deployment: true,
      },
    });

    expect(component.$el.querySelector('span').textContent).toContain('Re-deploy');
  });


  it('Should render Rollback label when is_last_deployment is false', () => {
    const component = new window.gl.environmentsList.RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retry_url: retryURL,
        is_last_deployment: false,
      },
    });

    expect(component.$el.querySelector('span').textContent).toContain('Rollback');
  });
});
