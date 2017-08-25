import Vue from 'vue';

export default (componentConfig, props = {}) => {
  let Component = componentConfig;

  // Make it instantiatable, if it's a plain config object
  if (typeof Component !== 'function' && typeof Component === 'object') {
    Component = Vue.extend(Component);
  }

  return new Component({
    propsData: props,
  }).$mount();
};

