import { shallowMount, createLocalVue } from '@vue/test-utils';
import SingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import { graphDataPrometheusQuery } from '../mock_data';

const localVue = createLocalVue();

describe('Single Stat Chart component', () => {
  let singleStatChart;

  beforeEach(() => {
    singleStatChart = shallowMount(localVue.extend(SingleStatChart), {
      propsData: {
        graphData: graphDataPrometheusQuery,
      },
      sync: false,
      localVue,
    });
  });

  afterEach(() => {
    singleStatChart.destroy();
  });

  describe('computed', () => {
    describe('engineeringNotation', () => {
      it('should interpolate the value and unit props', () => {
        expect(singleStatChart.vm.engineeringNotation).toBe('91MB');
      });
    });
  });
});
