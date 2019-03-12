import Vue from 'vue';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/vue_component_helper';
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
      it('should enclose part of project name in <b> & </b> which matches with `matcher` prop', done => {
        vm.matcher = 'lab';

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.js-frequent-items-item-title').innerHTML).toContain(
              '<b>L</b><b>a</b><b>b</b>',
            );
          })
          .then(done)
          .catch(done.fail);
      });

      it('should return project name as it is if `matcher` is not available', done => {
        vm.matcher = null;

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.js-frequent-items-item-title').innerHTML).toBe(
              mockProject.name,
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('truncatedNamespace', () => {
      it('should truncate project name from namespace string', done => {
        vm.namespace = 'platform / nokia-3310';

        vm.$nextTick()
          .then(() => {
            expect(
              trimText(vm.$el.querySelector('.js-frequent-items-item-namespace').innerHTML),
            ).toBe('platform');
          })
          .then(done)
          .catch(done.fail);
      });

      it('should truncate namespace string from the middle if it includes more than two groups in path', done => {
        vm.namespace = 'platform / hardware / broadcom / Wifi Group / Mobile Chipset / nokia-3310';

        vm.$nextTick()
          .then(() => {
            expect(
              trimText(vm.$el.querySelector('.js-frequent-items-item-namespace').innerHTML),
            ).toBe('platform / ... / Mobile Chipset');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('template', () => {
    it('should render component element', () => {
      expect(vm.$el.classList.contains('frequent-items-list-item-container')).toBeTruthy();
      expect(vm.$el.querySelectorAll('a').length).toBe(1);
      expect(vm.$el.querySelectorAll('.frequent-items-item-avatar-container').length).toBe(1);
      expect(vm.$el.querySelectorAll('.frequent-items-item-metadata-container').length).toBe(1);
      expect(vm.$el.querySelectorAll('.js-frequent-items-item-title').length).toBe(1);
      expect(vm.$el.querySelectorAll('.js-frequent-items-item-namespace').length).toBe(1);
    });
  });
});
