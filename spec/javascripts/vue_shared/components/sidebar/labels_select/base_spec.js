import Vue from 'vue';

import LabelsSelect from '~/labels_select';
import baseComponent from '~/vue_shared/components/sidebar/labels_select/base.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockConfig, mockLabels } from './mock_data';

const createComponent = (config = mockConfig) => {
  const Component = Vue.extend(baseComponent);

  return mountComponent(Component, config);
};

describe('BaseComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hiddenInputName', () => {
      it('returns correct string when showCreate prop is `true`', () => {
        expect(vm.hiddenInputName).toBe('issue[label_names][]');
      });

      it('returns correct string when showCreate prop is `false`', () => {
        const mockConfigNonEditable = Object.assign({}, mockConfig, { showCreate: false });
        const vmNonEditable = createComponent(mockConfigNonEditable);
        expect(vmNonEditable.hiddenInputName).toBe('label_id[]');
        vmNonEditable.$destroy();
      });
    });

    describe('createLabelTitle', () => {
      it('returns `Create project label` when `isProject` prop is true', () => {
        expect(vm.createLabelTitle).toBe('Create project label');
      });

      it('return `Create group label` when `isProject` prop is false', () => {
        const mockConfigGroup = Object.assign({}, mockConfig, { isProject: false });
        const vmGroup = createComponent(mockConfigGroup);
        expect(vmGroup.createLabelTitle).toBe('Create group label');
        vmGroup.$destroy();
      });
    });

    describe('manageLabelsTitle', () => {
      it('returns `Manage project labels` when `isProject` prop is true', () => {
        expect(vm.manageLabelsTitle).toBe('Manage project labels');
      });

      it('return `Manage group labels` when `isProject` prop is false', () => {
        const mockConfigGroup = Object.assign({}, mockConfig, { isProject: false });
        const vmGroup = createComponent(mockConfigGroup);
        expect(vmGroup.manageLabelsTitle).toBe('Manage group labels');
        vmGroup.$destroy();
      });
    });
  });

  describe('methods', () => {
    describe('handleClick', () => {
      it('emits onLabelClick event with label and list of labels as params', () => {
        spyOn(vm, '$emit');
        vm.handleClick(mockLabels[0]);
        expect(vm.$emit).toHaveBeenCalledWith('onLabelClick', mockLabels[0]);
      });
    });

    describe('handleCollapsedValueClick', () => {
      it('emits toggleCollapse event on component', () => {
        spyOn(vm, '$emit');
        vm.handleCollapsedValueClick();
        expect(vm.$emit).toHaveBeenCalledWith('toggleCollapse');
      });
    });

    describe('handleDropdownHidden', () => {
      it('emits onDropdownClose event on component', () => {
        spyOn(vm, '$emit');
        vm.handleDropdownHidden();
        expect(vm.$emit).toHaveBeenCalledWith('onDropdownClose');
      });
    });
  });

  describe('mounted', () => {
    it('creates LabelsSelect object and assigns it to `labelsDropdon` as prop', () => {
      expect(vm.labelsDropdown instanceof LabelsSelect).toBe(true);
    });
  });

  describe('template', () => {
    it('renders component container element with classes `block labels`', () => {
      expect(vm.$el.classList.contains('block')).toBe(true);
      expect(vm.$el.classList.contains('labels')).toBe(true);
    });

    it('renders `.selectbox` element', () => {
      expect(vm.$el.querySelector('.selectbox')).not.toBeNull();
      expect(vm.$el.querySelector('.selectbox').getAttribute('style')).toBe('display: none;');
    });

    it('renders `.dropdown` element', () => {
      expect(vm.$el.querySelector('.dropdown')).not.toBeNull();
    });

    it('renders `.dropdown-menu` element', () => {
      const dropdownMenuEl = vm.$el.querySelector('.dropdown-menu');
      expect(dropdownMenuEl).not.toBeNull();
      expect(dropdownMenuEl.querySelector('.dropdown-page-one')).not.toBeNull();
      expect(dropdownMenuEl.querySelector('.dropdown-content')).not.toBeNull();
      expect(dropdownMenuEl.querySelector('.dropdown-loading')).not.toBeNull();
    });
  });
});
