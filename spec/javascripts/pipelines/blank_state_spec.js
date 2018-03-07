import Vue from 'vue';
import component from '~/pipelines/components/blank_state.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('Pipelines Blank State', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(component);

    vm = mountComponent(Component,
      {
        svgPath: 'foo',
        message: 'Blank State',
      },
    );
  });

  it('should render svg', () => {
    expect(vm.$el.querySelector('.svg-content img').getAttribute('src')).toEqual('foo');
  });

  it('should render message', () => {
    expect(
      vm.$el.querySelector('h4').textContent.trim(),
    ).toEqual('Blank State');
  });
});
