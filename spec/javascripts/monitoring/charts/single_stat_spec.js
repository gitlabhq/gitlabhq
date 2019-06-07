import { shallowMount } from '@vue/test-utils';
import SingleStatChart from '~/monitoring/components/charts/single_stat.vue';

describe('Single Stat Chart component', () => {
  let singleStatChart;

  beforeEach(() => {
    singleStatChart = shallowMount(SingleStatChart, {
      propsData: {
        title: 'Time to render',
        value: 1,
        unit: 'sec',
      },
    });
  });

  afterEach(() => {
    singleStatChart.destroy();
  });

  describe('computed', () => {
    describe('valueWithUnit', () => {
      it('should interpolate the value and unit props', () => {
        expect(singleStatChart.vm.valueWithUnit).toBe('1sec');
      });
    });
  });
});
