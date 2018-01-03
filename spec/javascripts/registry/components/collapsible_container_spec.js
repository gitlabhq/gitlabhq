import Vue from 'vue';
import collapsibleComponent from '~/registry/components/collapsible_container.vue';
import store from '~/registry/stores';
import { repoPropsData } from '../mock_data';

describe('collapsible registry container', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(collapsibleComponent);
    vm = new Component({
      store,
      propsData: {
        repo: repoPropsData,
      },
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('toggle', () => {
    it('should be closed by default', () => {
      expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
      expect(vm.$el.querySelector('.container-image-head i').className).toEqual('fa fa-chevron-right');
    });

    it('should be open when user clicks on closed repo', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.container-image-tags')).toBeDefined();
        expect(vm.$el.querySelector('.container-image-head i').className).toEqual('fa fa-chevron-up');
        done();
      });
    });

    it('should be closed when the user clicks on an opened repo', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        vm.$el.querySelector('.js-toggle-repo').click();
        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
          expect(vm.$el.querySelector('.container-image-head i').className).toEqual('fa fa-chevron-right');
          done();
        });
      });
    });
  });

  describe('delete repo', () => {
    it('should be possible to delete a repo', () => {
      expect(vm.$el.querySelector('.js-remove-repo')).toBeDefined();
    });
  });
});
