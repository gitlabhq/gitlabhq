import Vue from 'vue';

import dropdownValueCollapsedComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockLabels } from './mock_data';

const createComponent = (labels = mockLabels) => {
  const Component = Vue.extend(dropdownValueCollapsedComponent);

  return mountComponent(Component, {
    labels,
  });
};

describe('DropdownValueCollapsedComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('labelsList', () => {
      it('returns empty text when `labels` prop is empty array', () => {
        const vmEmptyLabels = createComponent([]);
        expect(vmEmptyLabels.labelsList).toBe('Labels');
        vmEmptyLabels.$destroy();
      });

      it('returns labels names separated by coma when `labels` prop has more than one item', () => {
        const vmMoreLabels = createComponent(mockLabels.concat(mockLabels));
        expect(vmMoreLabels.labelsList).toBe('Foo Label, Foo Label');
        vmMoreLabels.$destroy();
      });

      it('returns labels names separated by coma with remaining labels count and `and more` phrase when `labels` prop has more than five items', () => {
        const mockMoreLabels = Object.assign([], mockLabels);
        for (let i = 0; i < 6; i += 1) {
          mockMoreLabels.unshift(mockLabels[0]);
        }

        const vmMoreLabels = createComponent(mockMoreLabels);
        expect(vmMoreLabels.labelsList).toBe('Foo Label, Foo Label, Foo Label, Foo Label, Foo Label, and 2 more');
        vmMoreLabels.$destroy();
      });

      it('returns first label name when `labels` prop has only one item present', () => {
        expect(vm.labelsList).toBe('Foo Label');
      });
    });
  });

  describe('methods', () => {
    describe('handleClick', () => {
      it('emits onValueClick event on component', () => {
        spyOn(vm, '$emit');
        vm.handleClick();
        expect(vm.$emit).toHaveBeenCalledWith('onValueClick');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with tooltip`', () => {
      expect(vm.$el.dataset.placement).toBe('left');
      expect(vm.$el.dataset.container).toBe('body');
      expect(vm.$el.dataset.originalTitle).toBe(vm.labelsList);
    });

    it('renders tags icon element', () => {
      expect(vm.$el.querySelector('.fa-tags')).not.toBeNull();
    });

    it('renders labels count', () => {
      expect(vm.$el.querySelector('span').innerText.trim()).toBe(`${vm.labels.length}`);
    });
  });
});
