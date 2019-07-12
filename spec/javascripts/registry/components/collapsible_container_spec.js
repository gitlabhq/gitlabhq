import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Vue from 'vue';
import collapsibleComponent from '~/registry/components/collapsible_container.vue';
import store from '~/registry/stores';
import * as types from '~/registry/stores/mutation_types';

import { repoPropsData, registryServerResponse, reposServerResponse } from '../mock_data';

describe('collapsible registry container', () => {
  let vm;
  let mock;
  const Component = Vue.extend(collapsibleComponent);

  const findDeleteBtn = () => vm.$el.querySelector('.js-remove-repo');

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet(repoPropsData.tagsPath).replyOnce(200, registryServerResponse, {});

    store.commit(types.SET_REPOS_LIST, reposServerResponse);

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
      expect(vm.iconName).toEqual('angle-right');
    });

    it('should be open when user clicks on closed repo', done => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.container-image-tags')).not.toBeNull();
        expect(vm.iconName).toEqual('angle-up');

        done();
      });
    });

    it('should be closed when the user clicks on an opened repo', done => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        vm.$el.querySelector('.js-toggle-repo').click();
        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
            expect(vm.iconName).toEqual('angle-right');
            done();
          });
        });
      });
    });
  });

  describe('delete repo', () => {
    it('should be possible to delete a repo', () => {
      expect(findDeleteBtn()).not.toBeNull();
    });

    it('should call deleteItem when confirming deletion', done => {
      findDeleteBtn().click();
      spyOn(vm, 'deleteItem').and.returnValue(Promise.resolve());

      Vue.nextTick(() => {
        document.querySelector(`#${vm.modalId} .btn-danger`).click();

        expect(vm.deleteItem).toHaveBeenCalledWith(vm.repo);
        done();
      });
    });
  });
});
