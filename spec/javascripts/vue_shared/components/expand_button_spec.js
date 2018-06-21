import Vue from 'vue';
import expandButton from '~/vue_shared/components/expand_button.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('expand button', () => {
  const Component = Vue.extend(expandButton);
  let vm;

  beforeEach(() => {
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
    expect(vm.$children[0].iconTestClass).toEqual('ic-ellipsis_h');
  });

  it('hides expander on click', done => {
    vm.$el.querySelector('button').click();
    vm.$nextTick(() => {
      expect(vm.$el.querySelector('button').getAttribute('style')).toEqual('display: none;');
      done();
    });
  });
});
