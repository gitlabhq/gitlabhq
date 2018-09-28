import Vue from 'vue';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockProject } from '../mock_data'; // can also use 'mockGroup', but not useful to test here

const createComponent = () => {
  const Component = Vue.extend(frequentItemsListItemComponent);

  return mountComponent(Component, {
    itemId: mockProject.id,
    itemName: mockProject.name,
    namespace: mockProject.namespace,
    webUrl: mockProject.webUrl,
    avatarUrl: mockProject.avatarUrl,
  });
};

describe('FrequentItemsListItemComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hasAvatar', () => {
      it('should return `true` or `false` if whether avatar is present or not', () => {
        vm.avatarUrl = 'path/to/avatar.png';
        expect(vm.hasAvatar).toBe(true);

        vm.avatarUrl = null;
        expect(vm.hasAvatar).toBe(false);
      });
    });

    describe('highlightedItemName', () => {
      it('should enclose part of project name in <b> & </b> which matches with `matcher` prop', () => {
        vm.matcher = 'lab';
        expect(vm.highlightedItemName).toContain('<b>Lab</b>');
      });

      it('should return project name as it is if `matcher` is not available', () => {
        vm.matcher = null;
        expect(vm.highlightedItemName).toBe(mockProject.name);
      });
    });

    describe('truncatedNamespace', () => {
      it('should truncate project name from namespace string', () => {
        vm.namespace = 'platform / nokia-3310';
        expect(vm.truncatedNamespace).toBe('platform');
      });

      it('should truncate namespace string from the middle if it includes more than two groups in path', () => {
        vm.namespace = 'platform / hardware / broadcom / Wifi Group / Mobile Chipset / nokia-3310';
        expect(vm.truncatedNamespace).toBe('platform / ... / Mobile Chipset');
      });
    });
  });

  describe('template', () => {
    it('should render component element', () => {
      expect(vm.$el.classList.contains('frequent-items-list-item-container')).toBeTruthy();
      expect(vm.$el.querySelectorAll('a').length).toBe(1);
      expect(vm.$el.querySelectorAll('.frequent-items-item-avatar-container').length).toBe(1);
      expect(vm.$el.querySelectorAll('.frequent-items-item-metadata-container').length).toBe(1);
      expect(vm.$el.querySelectorAll('.frequent-items-item-title').length).toBe(1);
      expect(vm.$el.querySelectorAll('.frequent-items-item-namespace').length).toBe(1);
    });
  });
});
