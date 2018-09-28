import Vue from 'vue';

import dropdownButtonComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_button.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockConfig, mockLabels } from './mock_data';

const componentConfig = Object.assign({}, mockConfig, {
  fieldName: 'label_id[]',
  labels: mockLabels,
  showExtraOptions: false,
});

const createComponent = (config = componentConfig) => {
  const Component = Vue.extend(dropdownButtonComponent);

  return mountComponent(Component, config);
};

describe('DropdownButtonComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('dropdownToggleText', () => {
      it('returns text as `Label` when `labels` prop is empty array', () => {
        const mockEmptyLabels = Object.assign({}, componentConfig, { labels: [] });
        const vmEmptyLabels = createComponent(mockEmptyLabels);
        expect(vmEmptyLabels.dropdownToggleText).toBe('Label');
        vmEmptyLabels.$destroy();
      });

      it('returns first label name with remaining label count when `labels` prop has more than one item', () => {
        const mockMoreLabels = Object.assign({}, componentConfig, {
          labels: mockLabels.concat(mockLabels),
        });
        const vmMoreLabels = createComponent(mockMoreLabels);
        expect(vmMoreLabels.dropdownToggleText).toBe('Foo Label +1 more');
        vmMoreLabels.$destroy();
      });

      it('returns first label name when `labels` prop has only one item present', () => {
        expect(vm.dropdownToggleText).toBe('Foo Label');
      });
    });
  });

  describe('template', () => {
    it('renders component container element of type `button`', () => {
      expect(vm.$el.nodeName).toBe('BUTTON');
    });

    it('renders component container element with required data attributes', () => {
      expect(vm.$el.dataset.abilityName).toBe(vm.abilityName);
      expect(vm.$el.dataset.fieldName).toBe(vm.fieldName);
      expect(vm.$el.dataset.issueUpdate).toBe(vm.updatePath);
      expect(vm.$el.dataset.labels).toBe(vm.labelsPath);
      expect(vm.$el.dataset.namespacePath).toBe(vm.namespace);
      expect(vm.$el.dataset.showAny).not.toBeDefined();
    });

    it('renders dropdown toggle text element', () => {
      const dropdownToggleTextEl = vm.$el.querySelector('.dropdown-toggle-text');
      expect(dropdownToggleTextEl).not.toBeNull();
      expect(dropdownToggleTextEl.innerText.trim()).toBe('Foo Label');
    });

    it('renders dropdown button icon', () => {
      const dropdownIconEl = vm.$el.querySelector('i.fa');
      expect(dropdownIconEl).not.toBeNull();
      expect(dropdownIconEl.classList.contains('fa-chevron-down')).toBe(true);
    });
  });
});
