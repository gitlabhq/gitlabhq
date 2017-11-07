import Vue from 'vue';
import GraphLegend from '~/monitoring/components/graph/legend.vue';
import measurements from '~/monitoring/utils/measurements';
import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from '../mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(GraphLegend);

  return new Component({
    propsData,
  }).$mount();
};

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);

const defaultValuesComponent = {
  graphWidth: 500,
  graphHeight: 300,
  graphHeightOffset: 120,
  margin: measurements.large.margin,
  measurements: measurements.large,
  areaColorRgb: '#f0f0f0',
  legendTitle: 'Title',
  yAxisLabel: 'Values',
  metricUsage: 'Value',
  unitOfDisplay: 'Req/Sec',
  currentDataIndex: 0,
};

const timeSeries = createTimeSeries(convertedMetrics[0].queries,
  defaultValuesComponent.graphWidth, defaultValuesComponent.graphHeight,
  defaultValuesComponent.graphHeightOffset);

defaultValuesComponent.timeSeries = timeSeries;

function getTextFromNode(component, selector) {
  return component.$el.querySelector(selector).firstChild.nodeValue.trim();
}

describe('GraphLegend', () => {
  describe('Computed props', () => {
    it('textTransform', () => {
      const component = createComponent(defaultValuesComponent);

      expect(component.textTransform).toContain('translate(15, 120) rotate(-90)');
    });

    it('xPosition', () => {
      const component = createComponent(defaultValuesComponent);

      expect(component.xPosition).toEqual(180);
    });

    it('yPosition', () => {
      const component = createComponent(defaultValuesComponent);

      expect(component.yPosition).toEqual(240);
    });

    it('rectTransform', () => {
      const component = createComponent(defaultValuesComponent);

      expect(component.rectTransform).toContain('translate(0, 120) rotate(-90)');
    });
  });

  describe('methods', () => {
    it('translateLegendGroup should only change Y direction', () => {
      const component = createComponent(defaultValuesComponent);

      const translatedCoordinate = component.translateLegendGroup(1);
      expect(translatedCoordinate.indexOf('translate(0, ')).not.toEqual(-1);
    });

    it('formatMetricUsage should contain the unit of display and the current value selected via "currentDataIndex"', () => {
      const component = createComponent(defaultValuesComponent);

      const formattedMetricUsage = component.formatMetricUsage(timeSeries[0]);
      const valueFromSeries = timeSeries[0].values[component.currentDataIndex].value;
      expect(formattedMetricUsage.indexOf(component.unitOfDisplay)).not.toEqual(-1);
      expect(formattedMetricUsage.indexOf(valueFromSeries)).not.toEqual(-1);
    });
  });

  it('has 2 rect-axis-text rect svg elements', () => {
    const component = createComponent(defaultValuesComponent);

    expect(component.$el.querySelectorAll('.rect-axis-text').length).toEqual(2);
  });

  it('contains text to signal the usage, title and time with multiple time series', () => {
    const component = createComponent(defaultValuesComponent);
    const titles = component.$el.querySelectorAll('.legend-metric-title');

    expect(titles[0].textContent.indexOf('1xx')).not.toEqual(-1);
    expect(titles[1].textContent.indexOf('2xx')).not.toEqual(-1);
    expect(getTextFromNode(component, '.y-label-text')).toEqual(component.yAxisLabel);
  });

  it('should contain the same number of legend groups as the timeSeries length', () => {
    const component = createComponent(defaultValuesComponent);

    expect(component.$el.querySelectorAll('.legend-group').length).toEqual(component.timeSeries.length);
  });
});
