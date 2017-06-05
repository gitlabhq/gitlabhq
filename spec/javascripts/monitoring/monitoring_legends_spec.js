import Vue from 'vue';
import MonitoringLegends from '~/monitoring/components/monitoring_legends.vue';
import measurements from '~/monitoring/utils/measurements';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringLegends);

  return new Component({
    propsData,
  });
};

function getTextFromNode(component, selector) {
  return component.$el.querySelector(selector).firstChild.nodeValue.trim();
}

describe('MonitoringLegends', () => {
  describe('Computed props', () => {
    it('calculateTextTransform', () => {
      const component = createComponent({
        width: 500,
        height: 300,
        margin: measurements.large.margin,
        measurements: measurements.large,
        areaColorRgb: '#f0f0f0',
        legendTitle: 'Title',
        yAxisLabel: 'Values',
        metricUsage: 'Value',
      });

      expect(typeof component.calculateTextTransform).toEqual('string');
      expect(component.calculateTextTransform.indexOf(120)).not.toEqual(-1);
    });

    it('calculateXPosition', () => {
      const component = createComponent({
        width: 500,
        height: 300,
        margin: measurements.large.margin,
        measurements: measurements.large,
        areaColorRgb: '#f0f0f0',
        legendTitle: 'Title',
        yAxisLabel: 'Values',
        metricUsage: 'Value',
      });

      expect(component.calculateXPosition).toEqual(180);
    });

    it('calculateYPosition', () => {
      const component = createComponent({
        width: 500,
        height: 300,
        margin: measurements.large.margin,
        measurements: measurements.large,
        areaColorRgb: '#f0f0f0',
        legendTitle: 'Title',
        yAxisLabel: 'Values',
        metricUsage: 'Value',
      });

      expect(component.calculateYPosition).toEqual(240);
    });
  });

  it('has 2 rect-axis-text rect svg elements', () => {
    const component = createComponent({
      width: 500,
      height: 300,
      margin: measurements.large.margin,
      measurements: measurements.large,
      areaColorRgb: '#f0f0f0',
      legendTitle: 'Title',
      yAxisLabel: 'Values',
      metricUsage: 'Value',
    });
    component.$mount();

    expect(component.$el.querySelectorAll('.rect-axis-text').length).toEqual(2);
  });

  it('contains text to signal the usage, title and time', () => {
    const component = createComponent({
      width: 500,
      height: 300,
      margin: measurements.large.margin,
      measurements: measurements.large,
      areaColorRgb: '#f0f0f0',
      legendTitle: 'Title',
      yAxisLabel: 'Values',
      metricUsage: 'Value',
    });
    component.$mount();

    expect(getTextFromNode(component, '.text-metric-title')).toEqual(component.legendTitle);
    expect(getTextFromNode(component, '.text-metric-usage')).toEqual(component.metricUsage);
    expect(getTextFromNode(component, '.label-axis-text')).toEqual(component.yAxisLabel);
  });
});
