import Vue from 'vue';
import identiconComponent from '~/vue_shared/components/identicon.vue';

const createComponent = () => {
  const Component = Vue.extend(identiconComponent);

  return new Component({
    propsData: {
      entityId: 1,
      entityName: 'entity-name',
    },
  }).$mount();
};

describe('IdenticonComponent', () => {
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
