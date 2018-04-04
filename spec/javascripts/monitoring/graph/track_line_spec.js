import Vue from 'vue';
import TrackLine from '~/monitoring/components/graph/track_line.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from '../mock_data';

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);
const timeSeries = createTimeSeries(convertedMetrics[0].queries, 500, 300, 120);

describe('TrackLine component', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(TrackLine);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Computed props', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { track: timeSeries[0] });
    });

    it('strokeDashArray', () => {
      const dashedArray = vm.strokeDashArray('dashed');
      const dottedArray = vm.strokeDashArray('dotted');

      expect(dashedArray).toEqual('6, 3');
      expect(dottedArray).toEqual('3, 3');
    });
  });
});
