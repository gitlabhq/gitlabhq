import $ from 'jquery';
import Vue from 'vue';
import { createStore } from '~/ide/stores';
import Dropdown from '~/ide/components/file_templates/dropdown.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { resetStore } from '../../helpers';

describe('IDE file templates dropdown component', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(Dropdown);
  });

  beforeEach(() => {
    const store = createStore();

    vm = createComponentWithStore(Component, store, {
      label: 'Test',
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
    resetStore(vm.$store);
  });

  describe('async', () => {
    beforeEach(() => {
      vm.async = true;
    });

    it('calls async store method on Bootstrap dropdown event', () => {
      spyOn(vm, 'fetchTemplateTypes').and.stub();

      $(vm.$el).trigger('show.bs.dropdown');

      expect(vm.fetchTemplateTypes).toHaveBeenCalled();
    });

    it('renders templates when async', done => {
      vm.$store.state.fileTemplates.templates = [
        {
          name: 'test',
        },
      ];

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-content').textContent).toContain('test');

        done();
      });
    });

    it('renders loading icon when isLoading is true', done => {
      vm.$store.state.fileTemplates.isLoading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

        done();
      });
    });

    it('searches template data', () => {
      vm.$store.state.fileTemplates.templates = [
        {
          name: 'test',
        },
      ];
      vm.searchable = true;
      vm.search = 'hello';

      expect(vm.outputData).toEqual([]);
    });

    it('does not filter data is searchable is false', () => {
      vm.$store.state.fileTemplates.templates = [
        {
          name: 'test',
        },
      ];
      vm.search = 'hello';

      expect(vm.outputData).toEqual([
        {
          name: 'test',
        },
      ]);
    });

    it('calls clickItem on click', done => {
      spyOn(vm, 'clickItem').and.stub();

      vm.$store.state.fileTemplates.templates = [
        {
          name: 'test',
        },
      ];

      vm.$nextTick(() => {
        vm.$el.querySelector('.dropdown-content button').click();

        expect(vm.clickItem).toHaveBeenCalledWith({
          name: 'test',
        });

        done();
      });
    });

    it('renders input when searchable is true', done => {
      vm.searchable = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-input')).not.toBe(null);

        done();
      });
    });

    it('does not render input when searchable is true & showLoading is true', done => {
      vm.searchable = true;
      vm.$store.state.fileTemplates.isLoading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-input')).toBe(null);

        done();
      });
    });
  });

  describe('sync', () => {
    beforeEach(done => {
      vm.data = [
        {
          name: 'test sync',
        },
      ];

      vm.$nextTick(done);
    });

    it('renders props data', () => {
      expect(vm.$el.querySelector('.dropdown-content').textContent).toContain('test sync');
    });

    it('renders input when searchable is true', done => {
      vm.searchable = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-input')).not.toBe(null);

        done();
      });
    });

    it('calls clickItem on click', done => {
      spyOn(vm, 'clickItem').and.stub();

      vm.$nextTick(() => {
        vm.$el.querySelector('.dropdown-content button').click();

        expect(vm.clickItem).toHaveBeenCalledWith({
          name: 'test sync',
        });

        done();
      });
    });

    it('searches template data', () => {
      vm.searchable = true;
      vm.search = 'hello';

      expect(vm.outputData).toEqual([]);
    });

    it('does not filter data is searchable is false', () => {
      vm.search = 'hello';

      expect(vm.outputData).toEqual([
        {
          name: 'test sync',
        },
      ]);
    });

    it('renders dropdown title', done => {
      vm.title = 'Test title';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-title').textContent).toContain('Test title');

        done();
      });
    });
  });
});
