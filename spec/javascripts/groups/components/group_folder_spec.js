import Vue from 'vue';

import groupFolderComponent from '~/groups/components/group_folder.vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import { mockGroups, mockParentGroupItem } from '../mock_data';

const createComponent = (groups = mockGroups, parentGroup = mockParentGroupItem) => {
  const Component = Vue.extend(groupFolderComponent);

  return new Component({
    propsData: {
      groups,
      parentGroup,
    },
  });
};

describe('GroupFolderComponent', () => {
  let vm;

  beforeEach((done) => {
    Vue.component('group-item', groupItemComponent);

    vm = createComponent();
    vm.$mount();

    Vue.nextTick(() => {
      done();
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hasMoreChildren', () => {
      it('should return false when childrenCount of group is less than MAX_CHILDREN_COUNT', () => {
        expect(vm.hasMoreChildren).toBeFalsy();
      });
    });

    describe('moreChildrenStats', () => {
      it('should return message with count of excess children over MAX_CHILDREN_COUNT limit', () => {
        expect(vm.moreChildrenStats).toBe('3 more items');
      });
    });
  });

  describe('template', () => {
    it('should render component template correctly', () => {
      expect(vm.$el.classList.contains('group-list-tree')).toBeTruthy();
      expect(vm.$el.querySelectorAll('li.group-row').length).toBe(7);
    });

    it('should render more children link when groups list has children over MAX_CHILDREN_COUNT limit', () => {
      const parentGroup = Object.assign({}, mockParentGroupItem);
      parentGroup.childrenCount = 21;

      const newVm = createComponent(mockGroups, parentGroup);
      newVm.$mount();
      expect(newVm.$el.querySelector('li.group-row a.has-more-items')).toBeDefined();
      newVm.$destroy();
    });
  });
});
