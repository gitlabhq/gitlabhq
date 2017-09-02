export default (Component, props = {}) => new Component({
  propsData: props,
}).$mount();

