import Vue from 'vue';
import identiconComponent from '~/vue_shared/components/identicon.vue';

const createComponent = (sizeClass) => {
  const Component = Vue.extend(identiconComponent);

  return new Component({
    propsData: {
      entityId: 1,
      entityName: 'entity-name',
      sizeClass,
    },
  }).$mount();
};

describe('IdenticonComponent', () => {
  describe('computed', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent();
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('identiconBackgroundClass', () => {
      it('should return bg class based on entityId', () => {
        vm.entityId = 4;

        expect(vm.identiconBackgroundClass).toBeDefined();
        expect(vm.identiconBackgroundClass).toBe('bg5');
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
      const vm = createComponent();

      expect(vm.$el.nodeName).toBe('DIV');
      expect(vm.$el.classList.contains('identicon')).toBeTruthy();
      expect(vm.$el.classList.contains('s40')).toBeTruthy();
      expect(vm.$el.classList.contains('bg2')).toBeTruthy();
      vm.$destroy();
    });

    it('should render identicon with provided sizing class', () => {
      const vm = createComponent('s32');

      expect(vm.$el.classList.contains('s32')).toBeTruthy();
      vm.$destroy();
    });
  });
});
