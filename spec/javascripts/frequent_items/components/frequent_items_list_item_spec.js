import Vue from 'vue';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { shallowMount } from '@vue/test-utils';
import { trimText } from 'spec/helpers/text_helper';
import { mockProject } from '../mock_data'; // can also use 'mockGroup', but not useful to test here

const createComponent = () => {
  const Component = Vue.extend(frequentItemsListItemComponent);

  return shallowMount(Component, {
    propsData: {
      itemId: mockProject.id,
      itemName: mockProject.name,
      namespace: mockProject.namespace,
      webUrl: mockProject.webUrl,
      avatarUrl: mockProject.avatarUrl,
    },
  });
};

describe('FrequentItemsListItemComponent', () => {
  let wrapper;
  let vm;

  beforeEach(() => {
    wrapper = createComponent();

    ({ vm } = wrapper);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hasAvatar', () => {
      it('should return `true` or `false` if whether avatar is present or not', () => {
        wrapper.setProps({ avatarUrl: 'path/to/avatar.png' });

        expect(vm.hasAvatar).toBe(true);

        wrapper.setProps({ avatarUrl: null });

        expect(vm.hasAvatar).toBe(false);
      });
    });

    describe('highlightedItemName', () => {
      it('should enclose part of project name in <b> & </b> which matches with `matcher` prop', () => {
        wrapper.setProps({ matcher: 'lab' });

        expect(wrapper.find('.js-frequent-items-item-title').html()).toContain(
          '<b>L</b><b>a</b><b>b</b>',
        );
      });

      it('should return project name as it is if `matcher` is not available', () => {
        wrapper.setProps({ matcher: null });

        expect(trimText(wrapper.find('.js-frequent-items-item-title').text())).toBe(
          mockProject.name,
        );
      });
    });

    describe('truncatedNamespace', () => {
      it('should truncate project name from namespace string', () => {
        wrapper.setProps({ namespace: 'platform / nokia-3310' });

        expect(trimText(wrapper.find('.js-frequent-items-item-namespace').text())).toBe('platform');
      });

      it('should truncate namespace string from the middle if it includes more than two groups in path', () => {
        wrapper.setProps({
          namespace: 'platform / hardware / broadcom / Wifi Group / Mobile Chipset / nokia-3310',
        });

        expect(trimText(wrapper.find('.js-frequent-items-item-namespace').text())).toBe(
          'platform / ... / Mobile Chipset',
        );
      });
    });
  });

  describe('template', () => {
    it('should render component element', () => {
      expect(wrapper.classes()).toContain('frequent-items-list-item-container');
      expect(wrapper.findAll('a').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-avatar-container').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-metadata-container').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-title').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-namespace').length).toBe(1);
    });
  });
});
