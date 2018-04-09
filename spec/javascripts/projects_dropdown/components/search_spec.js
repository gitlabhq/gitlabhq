import Vue from 'vue';

import searchComponent from '~/projects_dropdown/components/search.vue';
import eventHub from '~/projects_dropdown/event_hub';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = () => {
  const Component = Vue.extend(searchComponent);

  return mountComponent(Component);
};

describe('SearchComponent', () => {
  describe('methods', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent();
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('setFocus', () => {
      it('should set focus to search input', () => {
        spyOn(vm.$refs.search, 'focus');

        vm.setFocus();
        expect(vm.$refs.search.focus).toHaveBeenCalled();
      });
    });

    describe('emitSearchEvents', () => {
      it('should emit `searchProjects` event via eventHub when `searchQuery` present', () => {
        const searchQuery = 'test';
        spyOn(eventHub, '$emit');
        vm.searchQuery = searchQuery;
        vm.emitSearchEvents();
        expect(eventHub.$emit).toHaveBeenCalledWith('searchProjects', searchQuery);
      });

      it('should emit `searchCleared` event via eventHub when `searchQuery` is cleared', () => {
        spyOn(eventHub, '$emit');
        vm.searchQuery = '';
        vm.emitSearchEvents();
        expect(eventHub.$emit).toHaveBeenCalledWith('searchCleared');
      });
    });
  });

  describe('mounted', () => {
    it('should listen `dropdownOpen` event', (done) => {
      spyOn(eventHub, '$on');
      createComponent();

      Vue.nextTick(() => {
        expect(eventHub.$on).toHaveBeenCalledWith('dropdownOpen', jasmine.any(Function));
        done();
      });
    });
  });

  describe('beforeDestroy', () => {
    it('should unbind event listeners on eventHub', (done) => {
      const vm = createComponent();
      spyOn(eventHub, '$off');

      vm.$mount();
      vm.$destroy();

      Vue.nextTick(() => {
        expect(eventHub.$off).toHaveBeenCalledWith('dropdownOpen', jasmine.any(Function));
        done();
      });
    });
  });

  describe('template', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent();
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should render component element', () => {
      const inputEl = vm.$el.querySelector('input.form-control');

      expect(vm.$el.classList.contains('search-input-container')).toBeTruthy();
      expect(vm.$el.classList.contains('d-none d-sm-block')).toBeTruthy();
      expect(inputEl).not.toBe(null);
      expect(inputEl.getAttribute('placeholder')).toBe('Search your projects');
      expect(vm.$el.querySelector('.search-icon')).toBeDefined();
    });
  });
});
