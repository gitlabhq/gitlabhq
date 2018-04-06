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
    it('stylizedLine for dashed lineStyles', () => {
      vm = mountComponent(Component, { track: { ...timeSeries[0], lineStyle: 'dashed' } });

      expect(vm.stylizedLine).toEqual('6, 3');
    });

    it('stylizedLine for dotted lineStyles', () => {
      vm = mountComponent(Component, { track: { ...timeSeries[0], lineStyle: 'dotted' } });

      expect(vm.stylizedLine).toEqual('3, 3');
    });
  });

  describe('Rendered output', () => {
    it('has an svg with a line', () => {
      vm = mountComponent(Component, { track: { ...timeSeries[0] } });
      const svgEl = vm.$el.querySelector('svg');
      const lineEl = vm.$el.querySelector('svg line');

      expect(svgEl.getAttribute('width')).toEqual('15');
      expect(svgEl.getAttribute('height')).toEqual('6');

      expect(lineEl.getAttribute('stroke-width')).toEqual('4');
      expect(lineEl.getAttribute('x1')).toEqual('0');
      expect(lineEl.getAttribute('x2')).toEqual('15');
      expect(lineEl.getAttribute('y1')).toEqual('2');
      expect(lineEl.getAttribute('y2')).toEqual('2');
    });
  });
});
