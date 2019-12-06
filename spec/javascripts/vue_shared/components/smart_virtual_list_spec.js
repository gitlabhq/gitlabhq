import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import SmartVirtualScrollList from '~/vue_shared/components/smart_virtual_list.vue';

describe('Toggle Button', () => {
  let vm;

  const createComponent = ({ length, remain }) => {
    const smartListProperties = {
      rtag: 'section',
      wtag: 'ul',
      wclass: 'test-class',
      // Size in pixels does not matter for our tests here
      size: 35,
      length,
      remain,
    };

    const Component = Vue.extend({
      components: {
        SmartVirtualScrollList,
      },
      smartListProperties,
      items: Array(length).fill(1),
      template: `
      <smart-virtual-scroll-list v-bind="$options.smartListProperties">
        <li v-for="(val, key) in $options.items" :key="key">{{ key + 1 }}</li>
      </smart-virtual-scroll-list>`,
    });

    return mountComponent(Component);
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('if the list is shorter than the maximum shown elements', () => {
    const listLength = 10;

    beforeEach(() => {
      vm = createComponent({ length: listLength, remain: 20 });
    });

    it('renders without the vue-virtual-scroll-list component', () => {
      expect(vm.$el.classList).not.toContain('js-virtual-list');
      expect(vm.$el.classList).toContain('js-plain-element');
    });

    it('renders list with provided tags and classes for the wrapper elements', () => {
      expect(vm.$el.tagName).toEqual('SECTION');
      expect(vm.$el.firstChild.tagName).toEqual('UL');
      expect(vm.$el.firstChild.classList).toContain('test-class');
    });

    it('renders all children list elements', () => {
      expect(vm.$el.querySelectorAll('li').length).toEqual(listLength);
    });
  });

  describe('if the list is longer than the maximum shown elements', () => {
    const maxItemsShown = 20;

    beforeEach(() => {
      vm = createComponent({ length: 1000, remain: maxItemsShown });
    });

    it('uses the vue-virtual-scroll-list component', () => {
      expect(vm.$el.classList).toContain('js-virtual-list');
      expect(vm.$el.classList).not.toContain('js-plain-element');
    });

    it('renders list with provided tags and classes for the wrapper elements', () => {
      expect(vm.$el.tagName).toEqual('SECTION');
      expect(vm.$el.firstChild.tagName).toEqual('UL');
      expect(vm.$el.firstChild.classList).toContain('test-class');
    });

    it('renders at max twice the maximum shown elements', () => {
      expect(vm.$el.querySelectorAll('li').length).toBeLessThanOrEqual(2 * maxItemsShown);
    });
  });
});
