import Vue from 'vue';
import MonitoringFlag from '~/monitoring/components/monitoring_flag.vue';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringFlag);

  return new Component({
    propsData,
  }).$mount();
};

function getCoordinate(component, selector, coordinate) {
  const coordinateVal = component.$el.querySelector(selector).getAttribute(coordinate);
  return parseInt(coordinateVal, 10);
}

describe('MonitoringFlag', () => {
  it('has a line and a circle located at the currentXCoordinate and currentYCoordinate', () => {
    const component = createComponent({
      currentXCoordinate: 200,
      currentYCoordinate: 100,
      currentFlagPosition: 100,
      currentData: {
        time: new Date('2017-06-04T18:17:33.501Z'),
        value: '1.49609375',
      },
      graphHeight: 300,
      graphHeightOffset: 120,
    });

    expect(getCoordinate(component, '.selected-metric-line', 'x1'))
      .toEqual(component.currentXCoordinate);
    expect(getCoordinate(component, '.selected-metric-line', 'x2'))
      .toEqual(component.currentXCoordinate);
    expect(getCoordinate(component, '.circle-metric', 'cx'))
      .toEqual(component.currentXCoordinate);
    expect(getCoordinate(component, '.circle-metric', 'cy'))
      .toEqual(component.currentYCoordinate);
  });

  it('has a SVG with the class rect-text-metric at the currentFlagPosition', () => {
    const component = createComponent({
      currentXCoordinate: 200,
      currentYCoordinate: 100,
      currentFlagPosition: 100,
      currentData: {
        time: new Date('2017-06-04T18:17:33.501Z'),
        value: '1.49609375',
      },
      graphHeight: 300,
      graphHeightOffset: 120,
    });

    const svg = component.$el.querySelector('.rect-text-metric');
    expect(svg.tagName).toEqual('svg');
    expect(parseInt(svg.getAttribute('x'), 10)).toEqual(component.currentFlagPosition);
  });

  describe('Computed props', () => {
    it('calculatedHeight', () => {
      const component = createComponent({
        currentXCoordinate: 200,
        currentYCoordinate: 100,
        currentFlagPosition: 100,
        currentData: {
          time: new Date('2017-06-04T18:17:33.501Z'),
          value: '1.49609375',
        },
        graphHeight: 300,
        graphHeightOffset: 120,
      });

      expect(component.calculatedHeight).toEqual(180);
    });
  });
});
