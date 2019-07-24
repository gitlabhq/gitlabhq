import { shallowMount } from '@vue/test-utils';
import PanelType from '~/monitoring/components/panel_type.vue';
import EmptyChart from '~/monitoring/components/charts/empty_chart.vue';
import { graphDataPrometheusQueryRange } from './mock_data';

describe('Panel Type component', () => {
  let panelType;
  const dashboardWidth = 100;

  describe('When no graphData is available', () => {
    let glEmptyChart;
    const graphDataNoResult = graphDataPrometheusQueryRange;
    graphDataNoResult.queries[0].result = [];

    beforeEach(() => {
      panelType = shallowMount(PanelType, {
        propsData: {
          dashboardWidth,
          graphData: graphDataNoResult,
        },
      });
    });

    afterEach(() => {
      panelType.destroy();
    });

    describe('Empty Chart component', () => {
      beforeEach(() => {
        glEmptyChart = panelType.find(EmptyChart);
      });

      it('is a Vue instance', () => {
        expect(glEmptyChart.isVueInstance()).toBe(true);
      });

      it('it receives a graph title', () => {
        const props = glEmptyChart.props();

        expect(props.graphTitle).toBe(panelType.vm.graphData.title);
      });
    });
  });
});
