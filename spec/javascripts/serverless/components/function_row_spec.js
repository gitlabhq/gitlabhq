import Vue from 'vue';

import functionRowComponent from '~/serverless/components/function_row.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockServerlessFunction } from '../mock_data';

const createComponent = func => mountComponent(Vue.extend(functionRowComponent), { func });

describe('functionRowComponent', () => {
  it('Parses the function details correctly', () => {
    const vm = createComponent(mockServerlessFunction);

    expect(vm.$el.querySelector('b').innerHTML).toEqual(mockServerlessFunction.name);
    expect(vm.$el.querySelector('span').innerHTML).toEqual(mockServerlessFunction.image);
    expect(vm.$el.querySelector('time').getAttribute('data-original-title')).not.toBe(null);
    expect(vm.$el.querySelector('div.url-text-field').innerHTML).toEqual(
      mockServerlessFunction.url,
    );

    vm.$destroy();
  });

  it('handles clicks correctly', () => {
    const vm = createComponent(mockServerlessFunction);

    expect(vm.checkClass(vm.$el.querySelector('p'))).toBe(true); // check somewhere inside the row
    expect(vm.checkClass(vm.$el.querySelector('svg'))).toBe(false); // check a button image
    expect(vm.checkClass(vm.$el.querySelector('div.url-text-field'))).toBe(false); // check the url bar

    vm.$destroy();
  });
});
