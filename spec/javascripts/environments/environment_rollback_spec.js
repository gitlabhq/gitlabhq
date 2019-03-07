import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import eventHub from '~/environments/event_hub';
import rollbackComp from '~/environments/components/environment_rollback.vue';

describe('Rollback Component', () => {
  const retryUrl = 'https://gitlab.com/retry';
  let RollbackComponent;

  beforeEach(() => {
    RollbackComponent = Vue.extend(rollbackComp);
  });

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl,
        isLastDeployment: true,
        environment: {},
      },
    }).$mount();

    expect(component.$el).toHaveSpriteIcon('repeat');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    const component = new RollbackComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        retryUrl,
        isLastDeployment: false,
        environment: {},
      },
    }).$mount();

    expect(component.$el).toHaveSpriteIcon('redo');
  });

  it('should emit a "rollback" event on button click', () => {
    const eventHubSpy = spyOn(eventHub, '$emit');
    const component = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        environment: {
          name: 'test',
        },
      },
    });
    const button = component.find(GlButton);

    button.vm.$emit('click');

    expect(eventHubSpy).toHaveBeenCalledWith('requestRollbackEnvironment', {
      retryUrl,
      isLastDeployment: true,
      name: 'test',
    });
  });
});
