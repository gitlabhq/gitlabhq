import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import commitPipelineStatus from '~/pages/projects/tree/components/commit_pipeline_status_component.vue';
import mountComponent from '../helpers/vue_mount_component_helper';

describe('Commit pipeline status component', () => {
  let vm;
  let component;
  let mock;
  const mockCiStatus = {
    details_path: '/root/hello-world/pipelines/1',
    favicon: 'canceled.ico',
    group: 'canceled',
    has_details: true,
    icon: 'status_canceled',
    label: 'canceled',
    text: 'canceled',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/dummy/endpoint').reply(() => {
      const res = Promise.resolve([200, {
        pipelines: [
          {
            details: {
              status: mockCiStatus,
            },
          },
        ],
      }]);
      return res;
    });
    component = Vue.extend(commitPipelineStatus);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('While polling pipeline data', () => {
    beforeEach(() => {
      vm = mountComponent(component, {
        endpoint: '/dummy/endpoint',
      });
    });

    afterEach(() => {
      vm.poll.stop();
      vm.$destroy();
    });

    it('contains a ciStatus when the polling is succesful ', (done) => {
      setTimeout(() => {
        expect(vm.ciStatus).toEqual(mockCiStatus);
        done();
      }, 1000);
    });

    it('contains a ci-status icon when polling is succesful', (done) => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.ci-status-icon')).not.toBe(null);
        done();
      });
    });
  });
});
