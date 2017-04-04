class VueSpecHelper {
  static createComponent(Vue, componentName, propsData) {
    const Component = Vue.extend.call(Vue, componentName);

    return new Component({
      el: document.createElement('div'),
      propsData,
    });
  }
}

module.exports = VueSpecHelper;
