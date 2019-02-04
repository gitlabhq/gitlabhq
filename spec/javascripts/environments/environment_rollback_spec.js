import Vue from 'vue';
import rollbackComp from '~/environments/components/environment_rollback.vue';

describe('Rollback Component', () => {
  const retryURL = 'https://gitlab.com/retry';
  let RollbackComponent;

  beforeEach(() => {
    RollbackComponent = Vue.extend(rollbackComp);
  });

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: true,
      },
    }).$mount();

    expect(component.$el).toHaveSpriteIcon('repeat');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl: retryURL,
        isLastDeployment: false,
      },
    }).$mount();

    expect(component.$el).toHaveSpriteIcon('redo');
  });
});
