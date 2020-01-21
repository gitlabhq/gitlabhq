import { shallowMount, createLocalVue } from '@vue/test-utils';
import { trimText } from 'spec/helpers/text_helper';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { mockProject } from '../mock_data'; // can also use 'mockGroup', but not useful to test here

const localVue = createLocalVue();

describe('FrequentItemsListItemComponent', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(localVue.extend(frequentItemsListItemComponent), {
      propsData: {
        itemId: mockProject.id,
        itemName: mockProject.name,
        namespace: mockProject.namespace,
        webUrl: mockProject.webUrl,
        avatarUrl: mockProject.avatarUrl,
        ...props,
      },
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe('hasAvatar', () => {
      it('should return `true` or `false` if whether avatar is present or not', () => {
        createComponent({ avatarUrl: 'path/to/avatar.png' });

        expect(wrapper.vm.hasAvatar).toBe(true);
      });

      it('should return `false` if avatar is not present', () => {
        createComponent({ avatarUrl: null });

        expect(wrapper.vm.hasAvatar).toBe(false);
      });
    });

    describe('highlightedItemName', () => {
      it('should enclose part of project name in <b> & </b> which matches with `matcher` prop', () => {
        createComponent({ matcher: 'lab' });

        expect(wrapper.find('.js-frequent-items-item-title').html()).toContain(
          '<b>L</b><b>a</b><b>b</b>',
        );
      });

      it('should return project name as it is if `matcher` is not available', () => {
        createComponent({ matcher: null });

        expect(trimText(wrapper.find('.js-frequent-items-item-title').text())).toBe(
          mockProject.name,
        );
      });
    });

    describe('truncatedNamespace', () => {
      it('should truncate project name from namespace string', () => {
        createComponent({ namespace: 'platform / nokia-3310' });

        expect(trimText(wrapper.find('.js-frequent-items-item-namespace').text())).toBe('platform');
      });

      it('should truncate namespace string from the middle if it includes more than two groups in path', () => {
        createComponent({
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
      createComponent();

      expect(wrapper.classes()).toContain('frequent-items-list-item-container');
      expect(wrapper.findAll('a').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-avatar-container').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-metadata-container').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-title').length).toBe(1);
      expect(wrapper.findAll('.frequent-items-item-namespace').length).toBe(1);
    });
  });
});
