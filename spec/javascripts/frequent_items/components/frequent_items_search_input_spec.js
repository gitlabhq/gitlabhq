import searchComponent from '~/frequent_items/components/frequent_items_search_input.vue';
import eventHub from '~/frequent_items/event_hub';
import { shallowMount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();

const createComponent = (namespace = 'projects') =>
  shallowMount(localVue.extend(searchComponent), {
    propsData: { namespace },
    localVue,
    sync: false,
  });

describe('FrequentItemsSearchInputComponent', () => {
  let wrapper;
  let vm;

  beforeEach(() => {
    wrapper = createComponent();

    ({ vm } = wrapper);
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
      const vmX = createComponent().vm;

      localVue.nextTick(() => {
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
      const vmX = createComponent().vm;
      spyOn(eventHub, '$off');

      vmX.$mount();
      vmX.$destroy();

      localVue.nextTick(() => {
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
      expect(wrapper.classes()).toContain('search-input-container');
      expect(wrapper.contains('input.form-control')).toBe(true);
      expect(wrapper.contains('.search-icon')).toBe(true);
      expect(wrapper.find('input.form-control').attributes('placeholder')).toBe(
        'Search your projects',
      );
    });
  });
});
