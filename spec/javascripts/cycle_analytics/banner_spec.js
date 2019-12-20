import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import banner from '~/cycle_analytics/components/banner.vue';

describe('Cycle analytics banner', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(banner);
    vm = mountComponent(Component, {
      documentationLink: 'path',
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render cycle analytics information', () => {
    expect(vm.$el.querySelector('h4').textContent.trim()).toEqual('Introducing Cycle Analytics');

    expect(
      vm.$el
        .querySelector('p')
        .textContent.trim()
        .replace(/[\r\n]+/g, ' '),
    ).toContain(
      'Cycle Analytics gives an overview of how much time it takes to go from idea to production in your project.',
    );

    expect(vm.$el.querySelector('a').textContent.trim()).toEqual('Read more');

    expect(vm.$el.querySelector('a').getAttribute('href')).toEqual('path');
  });

  it('should emit an event when close button is clicked', () => {
    spyOn(vm, '$emit');

    vm.$el.querySelector('.js-ca-dismiss-button').click();

    expect(vm.$emit).toHaveBeenCalled();
  });
});
