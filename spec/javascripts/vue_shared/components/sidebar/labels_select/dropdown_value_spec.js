import Vue from 'vue';

import dropdownValueComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_value.vue';

import { mockConfig, mockLabels } from './mock_data';

import mountComponent from '../../../../helpers/vue_mount_component_helper';

const createComponent = (
  labels = mockLabels,
  labelFilterBasePath = mockConfig.labelFilterBasePath,
) => {
  const Component = Vue.extend(dropdownValueComponent);

  return mountComponent(Component, {
    labels,
    labelFilterBasePath,
  });
};

describe('DropdownValueComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isEmpty', () => {
      it('returns true if `labels` prop is empty', () => {
        const vmEmptyLabels = createComponent([]);
        expect(vmEmptyLabels.isEmpty).toBe(true);
        vmEmptyLabels.$destroy();
      });

      it('returns false if `labels` prop is empty', () => {
        expect(vm.isEmpty).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('labelFilterUrl', () => {
      it('returns URL string starting with labelFilterBasePath and encoded label.title', () => {
        expect(vm.labelFilterUrl({
          title: 'Foo bar',
        })).toBe('/gitlab-org/my-project/issues?label_name[]=Foo%20bar');
      });
    });

    describe('labelStyle', () => {
      it('returns object with `color` & `backgroundColor` properties from label.textColor & label.color', () => {
        const label = {
          textColor: '#FFFFFF',
          color: '#BADA55',
        };
        const styleObj = vm.labelStyle(label);

        expect(styleObj.color).toBe(label.textColor);
        expect(styleObj.backgroundColor).toBe(label.color);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with classes `hide-collapsed value issuable-show-labels`', () => {
      expect(vm.$el.classList.contains('hide-collapsed', 'value', 'issuable-show-labels')).toBe(true);
    });

    it('render slot content inside component when `labels` prop is empty', () => {
      const vmEmptyLabels = createComponent([]);
      expect(vmEmptyLabels.$el.querySelector('.text-secondary').innerText.trim()).toBe(mockConfig.emptyValueText);
      vmEmptyLabels.$destroy();
    });

    it('renders label element with filter URL', () => {
      expect(vm.$el.querySelector('a').getAttribute('href')).toBe('/gitlab-org/my-project/issues?label_name[]=Foo%20Label');
    });

    it('renders label element with tooltip and styles based on label details', () => {
      const labelEl = vm.$el.querySelector('a span.label.color-label');
      expect(labelEl).not.toBeNull();
      expect(labelEl.dataset.placement).toBe('bottom');
      expect(labelEl.dataset.container).toBe('body');
      expect(labelEl.dataset.originalTitle).toBe(mockLabels[0].description);
      expect(labelEl.getAttribute('style')).toBe('background-color: rgb(186, 218, 85);');
      expect(labelEl.innerText.trim()).toBe(mockLabels[0].title);
    });
  });
});
