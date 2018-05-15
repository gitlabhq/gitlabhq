import Vue from 'vue';

const mountComponent = (Component, props = {}, el = null) => new Component({
  propsData: props,
}).$mount(el);

export const createComponentWithStore = (Component, store, propsData = {}) => new Component({
  store,
  propsData,
});

export const createComponentWithMixin = (mixins = [], state = {}, props = {}, template = '<div></div>') => {
  const Component = Vue.extend({
    template,
    mixins,
    data() {
      return props;
    },
  });

  return mountComponent(Component, props);
};

export const mountComponentWithStore = (Component, { el, props, store }) =>
  new Component({
    store,
    propsData: props || { },
  }).$mount(el);

export default mountComponent;
