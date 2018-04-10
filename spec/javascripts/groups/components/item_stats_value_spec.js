import Vue from 'vue';

import itemStatsValueComponent from '~/groups/components/item_stats_value.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = ({ title, cssClass, iconName, tooltipPlacement, value }) => {
  const Component = Vue.extend(itemStatsValueComponent);

  return mountComponent(Component, {
    title,
    cssClass,
    iconName,
    tooltipPlacement,
    value,
  });
};

describe('ItemStatsValueComponent', () => {
  describe('computed', () => {
    let vm;
    const itemConfig = {
      title: 'Subgroups',
      cssClass: 'number-subgroups',
      iconName: 'folder',
      tooltipPlacement: 'left',
    };

    describe('isValuePresent', () => {
      it('returns true if non-empty `value` is present', () => {
        vm = createComponent(Object.assign({}, itemConfig, { value: 10 }));
        expect(vm.isValuePresent).toBeTruthy();
      });

      it('returns false if empty `value` is present', () => {
        vm = createComponent(itemConfig);
        expect(vm.isValuePresent).toBeFalsy();
      });

      afterEach(() => {
        vm.$destroy();
      });
    });
  });

  describe('template', () => {
    let vm;
    beforeEach(() => {
      vm = createComponent({
        title: 'Subgroups',
        cssClass: 'number-subgroups',
        iconName: 'folder',
        tooltipPlacement: 'left',
        value: 10,
      });
    });

    it('renders component element correctly', () => {
      expect(vm.$el.classList.contains('number-subgroups')).toBeTruthy();
      expect(vm.$el.querySelectorAll('svg').length > 0).toBeTruthy();
      expect(vm.$el.querySelectorAll('.stat-value').length > 0).toBeTruthy();
    });

    it('renders element tooltip correctly', () => {
      expect(vm.$el.dataset.originalTitle).toBe('Subgroups');
      expect(vm.$el.dataset.placement).toBe('left');
    });

    it('renders element icon correctly', () => {
      expect(vm.$el.querySelector('svg use').getAttribute('xlink:href')).toContain('folder');
    });

    it('renders value count correctly', () => {
      expect(vm.$el.querySelector('.stat-value').innerText.trim()).toContain('10');
    });

    afterEach(() => {
      vm.$destroy();
    });
  });
});
