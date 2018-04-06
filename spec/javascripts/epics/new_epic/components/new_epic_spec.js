import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import newEpic from 'ee/epics/new_epic/components/new_epic.vue';
import * as urlUtility from '~/lib/utils/url_utility';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('newEpic', () => {
  let vm;
  let mock;

  beforeEach(() => {
    const NewEpic = Vue.extend(newEpic);

    mock = new MockAdapter(axios);
    mock.onPost(gl.TEST_HOST).reply(200, { web_url: gl.TEST_HOST });
    vm = mountComponent(NewEpic, {
      endpoint: gl.TEST_HOST,
    });
  });

  afterEach(() => {
    mock.restore();
    vm.$destroy();
  });

  describe('alignRight', () => {
    it('should not add dropdown-menu-align-right by default', () => {
      expect(vm.$el.querySelector('.dropdown-menu').classList.contains('dropdown-menu-align-right')).toEqual(false);
    });

    it('should add dropdown-menu-align-right when alignRight', (done) => {
      vm.alignRight = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.dropdown-menu').classList.contains('dropdown-menu-align-right')).toEqual(true);
        done();
      });
    });
  });

  describe('creating epic', () => {
    it('should call createEpic service', (done) => {
      spyOn(urlUtility, 'visitUrl').and.callFake(() => {});
      spyOn(vm.service, 'createEpic').and.callThrough();

      vm.title = 'test';

      Vue.nextTick(() => {
        vm.$el.querySelector('.btn-save').click();
        expect(vm.service.createEpic).toHaveBeenCalled();
        done();
      });
    });

    it('should redirect to epic url after epic creation', (done) => {
      spyOn(urlUtility, 'visitUrl').and.callFake((url) => {
        expect(url).toEqual(gl.TEST_HOST);
        done();
      });

      vm.title = 'test';

      Vue.nextTick(() => {
        vm.$el.querySelector('.btn-save').click();
      });
    });

    it('should toggle loading button while creating', (done) => {
      spyOn(urlUtility, 'visitUrl').and.callFake(() => {});
      vm.title = 'test';

      Vue.nextTick(() => {
        const btnSave = vm.$el.querySelector('.btn-save');
        const loadingIcon = btnSave.querySelector('.js-loading-button-icon');

        expect(loadingIcon).toBeNull();
        btnSave.click();
        expect(loadingIcon).toBeDefined();
        done();
      });
    });
  });
});
