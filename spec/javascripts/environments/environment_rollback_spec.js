import Vue from 'vue';
import rollbackComp from '~/environments/components/environment_rollback.vue';

describe('Rollback Component', () => {
  const retryURL = 'https://gitlab.com/retry';
  let RollbackComponent;
  let spy;

  beforeEach(() => {
    RollbackComponent = Vue.extend(rollbackComp);
    spy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());
  });

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: true,
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    expect(component.$el.querySelector('span').textContent).toContain('Re-deploy');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: false,
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    expect(component.$el.querySelector('span').textContent).toContain('Rollback');
  });

  it('should call the service when the button is clicked', () => {
    const component = new RollbackComponent({
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: false,
        service: {
          postAction: spy,
        },
      },
    }).$mount();

    component.$el.click();

    expect(spy).toHaveBeenCalledWith(retryURL);
  });
});
