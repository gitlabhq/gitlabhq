import Vue from 'vue';
import TrackInfo from '~/monitoring/components/graph/track_info.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from '../mock_data';

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);
const timeSeries = createTimeSeries(convertedMetrics[0].queries, 500, 300, 120);

describe('TrackInfo component', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(TrackInfo);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Computed props', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { track: timeSeries[0] });
    });

    it('summaryMetrics', () => {
      expect(vm.summaryMetrics).toEqual('Avg: 0.000 · Max: 0.000');
    });
  });
});
