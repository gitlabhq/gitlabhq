import axios from '~/lib/utils/axios_utils';
import '~/performance_bar/components/performance_bar_app.vue';
import performanceBar from '~/performance_bar';
import PerformanceBarService from '~/performance_bar/services/performance_bar_service';

import MockAdapter from 'axios-mock-adapter';

describe('performance bar wrapper', () => {
  let mock;
  let vm;

  beforeEach(() => {
    const peekWrapper = document.createElement('div');

    peekWrapper.setAttribute('id', 'js-peek');
    peekWrapper.setAttribute('data-env', 'development');
    peekWrapper.setAttribute('data-request-id', '123');
    peekWrapper.setAttribute('data-peek-url', '/-/peek/results');
    peekWrapper.setAttribute('data-profile-url', '?lineprofiler=true');

    document.body.appendChild(peekWrapper);

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

    vm = performanceBar({ container: '#js-peek' });
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
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

      expect(vm.store.addRequest).toHaveBeenCalledWith('123', 'https://gitlab.com/');
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
