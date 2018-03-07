import Vue from 'vue';
import expandButton from '~/vue_shared/components/expand_button.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('expand button', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(expandButton);
    vm = mountComponent(Component, {
      slots: {
        expanded: '<p>Expanded!</p>',
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a collpased button', () => {
    expect(vm.$el.textContent.trim()).toEqual('...');
  });

  it('hides expander on click', (done) => {
    vm.$el.querySelector('button').click();
    vm.$nextTick(() => {
      expect(vm.$el.querySelector('button').getAttribute('style')).toEqual('display: none;');
      done();
    });
  });
});
