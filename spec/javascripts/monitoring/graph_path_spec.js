import Vue from 'vue';
import GraphPath from '~/monitoring/components/graph/path.vue';
import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(GraphPath);

  return new Component({
    propsData,
  }).$mount();
};

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);

const timeSeries = createTimeSeries(convertedMetrics[0].queries[0], 428, 272, 120);
const firstTimeSeries = timeSeries[0];

describe('Monitoring Paths', () => {
  it('renders two paths to represent a line and the area underneath it', () => {
    const component = createComponent({
      generatedLinePath: firstTimeSeries.linePath,
      generatedAreaPath: firstTimeSeries.areaPath,
      lineColor: firstTimeSeries.lineColor,
      areaColor: firstTimeSeries.areaColor,
    });
    const metricArea = component.$el.querySelector('.metric-area');
    const metricLine = component.$el.querySelector('.metric-line');

    expect(metricArea.getAttribute('fill')).toBe('#8fbce8');
    expect(metricArea.getAttribute('d')).toBe(firstTimeSeries.areaPath);
    expect(metricLine.getAttribute('stroke')).toBe('#1f78d1');
    expect(metricLine.getAttribute('d')).toBe(firstTimeSeries.linePath);
  });
});
