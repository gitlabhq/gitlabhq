import Vue from 'vue';
import callout from '~/vue_shared/components/callout.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('Callout Component', () => {
  let CalloutComponent;
  let vm;
  const exampleMessage = 'This is a callout message!';

  beforeEach(() => {
    CalloutComponent = Vue.extend(callout);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render the appropriate variant of callout', () => {
    vm = createComponent(CalloutComponent, {
      category: 'info',
      message: exampleMessage,
    });

    expect(vm.$el.getAttribute('class')).toEqual('bs-callout bs-callout-info');

    expect(vm.$el.tagName).toEqual('DIV');
  });

  it('should render accessibility attributes', () => {
    vm = createComponent(CalloutComponent, {
      message: exampleMessage,
    });

    expect(vm.$el.getAttribute('role')).toEqual('alert');
    expect(vm.$el.getAttribute('aria-live')).toEqual('assertive');
  });

  it('should render the provided message', () => {
    vm = createComponent(CalloutComponent, {
      message: exampleMessage,
    });

    expect(vm.$el.innerHTML.trim()).toEqual(exampleMessage);
  });
});
