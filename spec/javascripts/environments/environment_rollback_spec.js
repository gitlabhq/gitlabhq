const RollbackComponent = require('~/environments/components/environment_rollback');

describe('Rollback Component', () => {
  preloadFixtures('static/environments/element.html.raw');

  const retryURL = 'https://gitlab.com/retry';

  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');
  });

  it('Should link to the provided retryUrl', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: true,
      },
    });

    expect(component.$el.getAttribute('href')).toEqual(retryURL);
  });

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: true,
      },
    });

    expect(component.$el.querySelector('span').textContent).toContain('Re-deploy');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: false,
      },
    });

    expect(component.$el.querySelector('span').textContent).toContain('Rollback');
  });
});
