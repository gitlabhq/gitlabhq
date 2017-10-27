export default (Component, props = {}, el = null) => new Component({
  propsData: props,
}).$mount(el);
