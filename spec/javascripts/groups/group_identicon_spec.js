import Vue from 'vue';
import groupIdenticonComponent from '~/groups/components/group_identicon.vue';
import GroupsStore from '~/groups/stores/groups_store';
import { group1 } from './mock_data';

const createComponent = () => {
  const Component = Vue.extend(groupIdenticonComponent);
  const store = new GroupsStore();
  const group = store.decorateGroup(group1);

  return new Component({
    el: document.createElement('div'),
    propsData: {
      entityId: group.id,
      entityName: group.name,
    },
  });
};

describe('GroupIdenticonComponent', () => {
  let vm;
  let el;

  beforeEach(() => {
    vm = createComponent();
    el = vm.$el;
  });

  describe('props', () => {
    it('should have props with defined data types', (done) => {
      const identiconProps = groupIdenticonComponent.props;
      const EntityIdTypeClass = identiconProps.entityId.type;
      const EntityNameTypeClass = identiconProps.entityName.type;

      Vue.nextTick(() => {
        expect(identiconProps.entityId).toBeDefined();
        expect(new EntityIdTypeClass() instanceof Number).toBeTruthy();
        expect(identiconProps.entityId.required).toBeTruthy();

        expect(identiconProps.entityName).toBeDefined();
        expect(new EntityNameTypeClass() instanceof String).toBeTruthy();
        expect(identiconProps.entityName.required).toBeTruthy();
        done();
      });
    });
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
      expect(el.nodeName).toBe('DIV');
      expect(el.classList.contains('identicon')).toBeTruthy();
      expect(el.getAttribute('style').indexOf('background-color') > -1).toBeTruthy();
    });
  });
});
