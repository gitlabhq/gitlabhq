import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import commitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Commit pipeline status component', () => {
  let vm;
  let Component;
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
    Component = Vue.extend(commitPipelineStatus);
  });

  describe('While polling pipeline data succesfully', () => {
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
      vm = mountComponent(Component, {
        endpoint: '/dummy/endpoint',
      });
    });

    afterEach(() => {
      vm.poll.stop();
      vm.$destroy();
      mock.restore();
    });

    it('shows the loading icon when polling is starting', (done) => {
      expect(vm.$el.querySelector('.loading-container')).not.toBe(null);
      setTimeout(() => {
        expect(vm.$el.querySelector('.loading-container')).toBe(null);
        done();
      });
    });

    it('contains a ciStatus when the polling is succesful ', (done) => {
      setTimeout(() => {
        expect(vm.ciStatus).toEqual(mockCiStatus);
        done();
      });
    });

    it('contains a ci-status icon when polling is succesful', (done) => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.ci-status-icon')).not.toBe(null);
        expect(vm.$el.querySelector('.ci-status-icon').classList).toContain(`ci-status-icon-${mockCiStatus.group}`);
        done();
      });
    });
  });

  describe('When polling data was not succesful', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet('/dummy/endpoint').reply(() => {
        const res = Promise.reject([502, { }]);
        return res;
      });
      vm = new Component({
        props: {
          endpoint: '/dummy/endpoint',
        },
      });
    });

    afterEach(() => {
      vm.poll.stop();
      vm.$destroy();
      mock.restore();
    });

    it('calls an errorCallback', (done) => {
      spyOn(vm, 'errorCallback').and.callThrough();
      vm.$mount();
      setTimeout(() => {
        expect(vm.errorCallback.calls.count()).toEqual(1);
        done();
      });
    });
  });
});
