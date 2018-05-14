import Vue from 'vue';

import dropdownCreateLabelComponent from '~/vue_shared/components/sidebar/labels_select/dropdown_create_label.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockSuggestedColors } from './mock_data';

const createComponent = (headerTitle) => {
  const Component = Vue.extend(dropdownCreateLabelComponent);

  return mountComponent(Component, {
    headerTitle,
  });
};

describe('DropdownCreateLabelComponent', () => {
  let vm;

  beforeEach(() => {
    gon.suggested_label_colors = mockSuggestedColors;
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('created', () => {
    it('initializes `suggestedColors` prop on component from `gon.suggested_color_labels` object', () => {
      expect(vm.suggestedColors.length).toBe(mockSuggestedColors.length);
    });
  });

  describe('template', () => {
    it('renders component container element with classes `dropdown-page-two dropdown-new-label`', () => {
      expect(vm.$el.classList.contains('dropdown-page-two', 'dropdown-new-label')).toBe(true);
    });

    it('renders `Go back` button on component header', () => {
      const backButtonEl = vm.$el.querySelector('.dropdown-title button.dropdown-title-button.dropdown-menu-back');
      expect(backButtonEl).not.toBe(null);
      expect(backButtonEl.querySelector('.fa-arrow-left')).not.toBe(null);
    });

    it('renders component header element as `Create new label` when `headerTitle` prop is not provided', () => {
      const headerEl = vm.$el.querySelector('.dropdown-title');
      expect(headerEl.innerText.trim()).toContain('Create new label');
    });

    it('renders component header element with value of `headerTitle` prop', () => {
      const headerTitle = 'Create project label';
      const vmWithHeaderTitle = createComponent(headerTitle);
      const headerEl = vmWithHeaderTitle.$el.querySelector('.dropdown-title');
      expect(headerEl.innerText.trim()).toContain(headerTitle);
      vmWithHeaderTitle.$destroy();
    });

    it('renders `Close` button on component header', () => {
      const closeButtonEl = vm.$el.querySelector('.dropdown-title button.dropdown-title-button.dropdown-menu-close');
      expect(closeButtonEl).not.toBe(null);
      expect(closeButtonEl.querySelector('.fa-times.dropdown-menu-close-icon')).not.toBe(null);
    });

    it('renders `Name new label` input element', () => {
      expect(vm.$el.querySelector('.dropdown-labels-error.js-label-error')).not.toBe(null);
      expect(vm.$el.querySelector('input#new_label_name.default-dropdown-input')).not.toBe(null);
    });

    it('renders suggested colors list elements', () => {
      const colorsListContainerEl = vm.$el.querySelector('.suggest-colors.suggest-colors-dropdown');
      expect(colorsListContainerEl).not.toBe(null);
      expect(colorsListContainerEl.querySelectorAll('a').length).toBe(mockSuggestedColors.length);

      const colorItemEl = colorsListContainerEl.querySelectorAll('a')[0];
      expect(colorItemEl.dataset.color).toBe(vm.suggestedColors[0]);
      expect(colorItemEl.getAttribute('style')).toBe('background-color: rgb(0, 51, 204);');
    });

    it('renders color input element', () => {
      expect(vm.$el.querySelector('.dropdown-label-color-input')).not.toBe(null);
      expect(vm.$el.querySelector('.dropdown-label-color-preview.js-dropdown-label-color-preview')).not.toBe(null);
      expect(vm.$el.querySelector('input#new_label_color.default-dropdown-input')).not.toBe(null);
    });

    it('renders component action buttons', () => {
      const createBtnEl = vm.$el.querySelector('button.js-new-label-btn');
      const cancelBtnEl = vm.$el.querySelector('button.js-cancel-label-btn');
      expect(createBtnEl).not.toBe(null);
      expect(createBtnEl.innerText.trim()).toBe('Create');
      expect(cancelBtnEl.innerText.trim()).toBe('Cancel');
    });
  });
});
