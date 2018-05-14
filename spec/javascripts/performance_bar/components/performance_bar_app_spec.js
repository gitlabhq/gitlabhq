import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import performanceBarApp from '~/performance_bar/components/performance_bar_app.vue';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';
import PerformanceBarStore from '~/performance_bar/stores/performance_bar_store';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import MockAdapter from 'axios-mock-adapter';

describe('performance bar', () => {
  let mock;
  let vm;

  beforeEach(() => {
    const store = new PerformanceBarStore();

    mock = new MockAdapter(axios);

    mock.onGet('/-/peek/results').reply(
      200,
      {
        data: {
          gc: {
            invokes: 0,
            invoke_time: '0.00',
            use_size: 0,
            total_size: 0,
            total_object: 0,
            gc_time: '0.00',
          },
          host: { hostname: 'web-01' },
        },
      },
      {},
    );

    vm = mountComponent(Vue.extend(performanceBarApp), {
      store,
      env: 'development',
      requestId: '123',
      peekUrl: '/-/peek/results',
      profileUrl: '?lineprofiler=true',
    });
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  it('sets the class to match the environment', () => {
    expect(vm.$el.getAttribute('class')).toContain('development');
  });

  describe('loadRequestDetails', () => {
    beforeEach(() => {
      spyOn(vm.store, 'addRequest').and.callThrough();
    });

    it('does nothing if the request cannot be tracked', () => {
      spyOn(vm.store, 'canTrackRequest').and.callFake(() => false);

      vm.loadRequestDetails('123', 'https://gitlab.com/');

      expect(vm.store.addRequest).not.toHaveBeenCalled();
    });

    it('adds the request immediately', () => {
      vm.loadRequestDetails('123', 'https://gitlab.com/');

      expect(vm.store.addRequest).toHaveBeenCalledWith(
        '123',
        'https://gitlab.com/',
      );
    });

    it('makes an HTTP request for the request details', () => {
      spyOn(PerformanceBarService, 'fetchRequestDetails').and.callThrough();

      vm.loadRequestDetails('456', 'https://gitlab.com/');

      expect(PerformanceBarService.fetchRequestDetails).toHaveBeenCalledWith(
        '/-/peek/results',
        '456',
      );
    });
  });
});
