import Vue from 'vue';
import GraphFlag from '~/monitoring/components/graph/flag.vue';

const createComponent = (propsData) => {
  const Component = Vue.extend(GraphFlag);

  return new Component({
    propsData,
  }).$mount();
};

function getCoordinate(component, selector, coordinate) {
  const coordinateVal = component.$el.querySelector(selector).getAttribute(coordinate);
  return parseInt(coordinateVal, 10);
}

const defaultValuesComponent = {
  currentXCoordinate: 200,
  currentYCoordinate: 100,
  currentFlagPosition: 100,
  currentData: {
    time: new Date('2017-06-04T18:17:33.501Z'),
    value: '1.49609375',
  },
  graphHeight: 300,
  graphHeightOffset: 120,
  showFlagContent: true,
};

describe('GraphFlag', () => {
  it('has a line and a circle located at the currentXCoordinate and currentYCoordinate', () => {
    const component = createComponent(defaultValuesComponent);

    expect(getCoordinate(component, '.selected-metric-line', 'x1'))
      .toEqual(component.currentXCoordinate);
    expect(getCoordinate(component, '.selected-metric-line', 'x2'))
      .toEqual(component.currentXCoordinate);
  });

  it('has a SVG with the class rect-text-metric at the currentFlagPosition', () => {
    const component = createComponent(defaultValuesComponent);

    const svg = component.$el.querySelector('.rect-text-metric');
    expect(svg.tagName).toEqual('svg');
    expect(parseInt(svg.getAttribute('x'), 10)).toEqual(component.currentFlagPosition);
  });

  describe('Computed props', () => {
    it('calculatedHeight', () => {
      const component = createComponent(defaultValuesComponent);

      expect(component.calculatedHeight).toEqual(180);
    });
  });
});
