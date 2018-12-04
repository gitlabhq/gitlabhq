import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Vue from 'vue';
import collapsibleComponent from '~/registry/components/collapsible_container.vue';
import store from '~/registry/stores';
import { repoPropsData, registryServerResponse } from '../mock_data';

describe('collapsible registry container', () => {
  let vm;
  let mock;
  const Component = Vue.extend(collapsibleComponent);

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock
      .onGet(repoPropsData.tagsPath)
      .replyOnce(200, registryServerResponse, {});

    vm = new Component({
      store,
      propsData: {
        repo: repoPropsData,
      },
    }).$mount();
  });

  afterEach(() => {
    mock.restore();
    vm.$destroy();
  });

  describe('toggle', () => {
    it('should be closed by default', () => {
      expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
      expect(vm.$el.querySelector('.container-image-head i').className).toEqual(
        'fa fa-chevron-right',
      );
    });

    fit('should be open when user clicks on closed repo', done => {

      console.log(vm.repo, vm.$el)

      vm.$el.querySelector('.js-toggle-repo').click();
      
      Vue.nextTick(() => {
      
        console.log('nextTick', vm.repo, vm.$el)
      
        expect(vm.$el.querySelector('.container-image-tags')).not.toBeNull();
        expect(vm.$el.querySelector('.container-image-head i').className).toEqual(
          'fa fa-chevron-up',
        );
        done();
      });
    });

    it('should be closed when the user clicks on an opened repo', done => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        vm.$el.querySelector('.js-toggle-repo').click();
        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
          expect(vm.$el.querySelector('.container-image-head i').className).toEqual(
            'fa fa-chevron-right',
          );
          done();
        });
      });
    });
  });

  describe('delete repo', () => {
    it('should be possible to delete a repo', () => {
      expect(vm.$el.querySelector('.js-remove-repo')).not.toBeNull();
    });
  });
});
