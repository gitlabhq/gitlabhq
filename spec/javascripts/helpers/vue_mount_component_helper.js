export const createComponentWithStore = (Component, store, propsData = {}) => new Component({
  store,
  propsData,
});

export default (Component, props = {}, el = null) => new Component({
  propsData: props,
}).$mount(el);
