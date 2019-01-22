import Vue from 'vue';

import urlComponent from '~/serverless/components/url.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = uri => {
  const component = Vue.extend(urlComponent);

  return mountComponent(component, {
    uri,
  });
};

describe('urlComponent', () => {
  it('should render correctly', () => {
    const uri = 'http://testfunc.apps.example.com';
    const vm = createComponent(uri);

    expect(vm.$el.classList.contains('clipboard-group')).toBe(true);
    expect(vm.$el.querySelector('.js-clipboard-btn').getAttribute('data-clipboard-text')).toEqual(
      uri,
    );

    expect(vm.$el.querySelector('.url-text-field').innerHTML).toEqual(uri);

    vm.$destroy();
  });
});
