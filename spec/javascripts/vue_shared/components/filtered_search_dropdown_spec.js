import Vue from 'vue';
import component from '~/vue_shared/components/filtered_search_dropdown.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Filtered search dropdown', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with an empty array of items', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        items: [],
        filterKey: '',
      });
    });

    it('renders empty list', () => {
      expect(vm.$el.querySelectorAll('.js-filtered-dropdown-result').length).toEqual(0);
    });

    it('renders filter input', () => {
      expect(vm.$el.querySelector('.js-filtered-dropdown-input')).not.toBeNull();
    });
  });

  describe('when visible numbers is less than the items length', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        items: [{ title: 'One' }, { title: 'Two' }, { title: 'Three' }],
        visibleItems: 2,
        filterKey: 'title',
      });
    });

    it('it renders only the maximum number provided', () => {
      expect(vm.$el.querySelectorAll('.js-filtered-dropdown-result').length).toEqual(2);
    });
  });

  describe('when visible number is bigger than the items length', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        items: [{ title: 'One' }, { title: 'Two' }, { title: 'Three' }],
        filterKey: 'title',
      });
    });

    it('it renders the full list of items the maximum number provided', () => {
      expect(vm.$el.querySelectorAll('.js-filtered-dropdown-result').length).toEqual(3);
    });
  });

  describe('while filtering', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        items: [
          { title: 'One' },
          { title: 'Two/three' },
          { title: 'Three four' },
          { title: 'Five' },
        ],
        filterKey: 'title',
      });
    });

    it('updates the results to match the typed value', done => {
      vm.$el.querySelector('.js-filtered-dropdown-input').value = 'three';
      vm.$el.querySelector('.js-filtered-dropdown-input').dispatchEvent(new Event('input'));
      vm.$nextTick(() => {
        expect(vm.$el.querySelectorAll('.js-filtered-dropdown-result').length).toEqual(2);
        done();
      });
    });

    describe('when no value matches the typed one', () => {
      it('does not render any result', done => {
        vm.$el.querySelector('.js-filtered-dropdown-input').value = 'six';
        vm.$el.querySelector('.js-filtered-dropdown-input').dispatchEvent(new Event('input'));

        vm.$nextTick(() => {
          expect(vm.$el.querySelectorAll('.js-filtered-dropdown-result').length).toEqual(0);
          done();
        });
      });
    });
  });
});
