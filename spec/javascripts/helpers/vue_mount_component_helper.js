export const createComponentWithStore = (Component, store, propsData = {}) => new Component({
  store,
  propsData,
});

export const mountComponentWithStore = (Component, { el, props, store }) =>
  new Component({
    store,
    propsData: props || { },
  }).$mount(el);

export default (Component, props = {}, el = null) => new Component({
  propsData: props,
}).$mount(el);
