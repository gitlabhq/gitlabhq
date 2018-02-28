import Vue from 'vue';
import groupIdenticonComponent from '~/groups/components/group_identicon.vue';
import GroupsStore from '~/groups/stores/groups_store';
import { group1 } from './mock_data';

const createComponent = () => {
  const Component = Vue.extend(groupIdenticonComponent);
  const store = new GroupsStore();
  const group = store.decorateGroup(group1);

  return new Component({
    propsData: {
      entityId: group.id,
      entityName: group.name,
    },
  }).$mount();
};

describe('GroupIdenticonComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  describe('computed', () => {
    describe('identiconStyles', () => {
      it('should return styles attribute value with `background-color` property', () => {
        vm.entityId = 4;

        expect(vm.identiconStyles).toBeDefined();
        expect(vm.identiconStyles.indexOf('background-color: #E0F2F1;') > -1).toBeTruthy();
      });

      it('should return styles attribute value with `color` property', () => {
        vm.entityId = 4;

        expect(vm.identiconStyles).toBeDefined();
        expect(vm.identiconStyles.indexOf('color: #555;') > -1).toBeTruthy();
      });
    });

    describe('identiconTitle', () => {
      it('should return first letter of entity title in uppercase', () => {
        vm.entityName = 'dummy-group';

        expect(vm.identiconTitle).toBeDefined();
        expect(vm.identiconTitle).toBe('D');
      });
    });
  });

  describe('template', () => {
    it('should render identicon', () => {
      expect(vm.$el.nodeName).toBe('DIV');
      expect(vm.$el.classList.contains('identicon')).toBeTruthy();
      expect(vm.$el.getAttribute('style').indexOf('background-color') > -1).toBeTruthy();
    });
  });
});
