import Vue from 'vue';
import searchComponent from '~/frequent_items/components/frequent_items_search_input.vue';
import eventHub from '~/frequent_items/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = (namespace = 'projects') => {
  const Component = Vue.extend(searchComponent);

  return mountComponent(Component, { namespace });
};

describe('FrequentItemsSearchInputComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('setFocus', () => {
      it('should set focus to search input', () => {
        spyOn(vm.$refs.search, 'focus');

        vm.setFocus();
        expect(vm.$refs.search.focus).toHaveBeenCalled();
      });
    });
  });

  describe('mounted', () => {
    it('should listen `dropdownOpen` event', done => {
      spyOn(eventHub, '$on');
      const vmX = createComponent();

      Vue.nextTick(() => {
        expect(eventHub.$on).toHaveBeenCalledWith(
          `${vmX.namespace}-dropdownOpen`,
          jasmine.any(Function),
        );
        done();
      });
    });
  });

  describe('beforeDestroy', () => {
    it('should unbind event listeners on eventHub', done => {
      const vmX = createComponent();
      spyOn(eventHub, '$off');

      vmX.$mount();
      vmX.$destroy();

      Vue.nextTick(() => {
        expect(eventHub.$off).toHaveBeenCalledWith(
          `${vmX.namespace}-dropdownOpen`,
          jasmine.any(Function),
        );
        done();
      });
    });
  });

  describe('template', () => {
    it('should render component element', () => {
      const inputEl = vm.$el.querySelector('input.form-control');

      expect(vm.$el.classList.contains('search-input-container')).toBeTruthy();
      expect(inputEl).not.toBe(null);
      expect(inputEl.getAttribute('placeholder')).toBe('Search your projects');
      expect(vm.$el.querySelector('.search-icon')).toBeDefined();
    });
  });
});
