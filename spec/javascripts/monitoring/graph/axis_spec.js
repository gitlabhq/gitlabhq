import Vue from 'vue';
import GraphAxis from '~/monitoring/components/graph/axis.vue';
import measurements from '~/monitoring/utils/measurements';

const createComponent = propsData => {
  const Component = Vue.extend(GraphAxis);

  return new Component({
    propsData,
  }).$mount();
};

const defaultValuesComponent = {
  graphWidth: 500,
  graphHeight: 300,
  graphHeightOffset: 120,
  margin: measurements.large.margin,
  measurements: measurements.large,
  yAxisLabel: 'Values',
};

function getTextFromNode(component, selector) {
  return component.$el.querySelector(selector).firstChild.nodeValue.trim();
}

describe('Axis', () => {
  describe('Computed props', () => {
    it('textTransform', () => {
      const component = createComponent(defaultValuesComponent);

      expect(component.textTransform).toContain(
        'translate(15, 120) rotate(-90)',
      );
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

      expect(component.rectTransform).toContain(
        'translate(0, 120) rotate(-90)',
      );
    });
  });

  it('has 2 rect-axis-text rect svg elements', () => {
    const component = createComponent(defaultValuesComponent);

    expect(component.$el.querySelectorAll('.rect-axis-text').length).toEqual(2);
  });

  it('contains text to signal the usage, title and time with multiple time series', () => {
    const component = createComponent(defaultValuesComponent);

    expect(getTextFromNode(component, '.y-label-text')).toEqual(
      component.yAxisLabel,
    );
  });
});
