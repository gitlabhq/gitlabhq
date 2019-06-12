import { shallowMount } from '@vue/test-utils';
import { GlAreaChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { shallowWrapperContainsSlotText } from 'spec/helpers/vue_test_utils_helper';
import Area from '~/monitoring/components/charts/area.vue';
import { createStore } from '~/monitoring/stores';
import * as types from '~/monitoring/stores/mutation_types';
import MonitoringMock, { deploymentData } from '../mock_data';

describe('Area component', () => {
  const mockWidgets = 'mockWidgets';
  const mockSvgPathContent = 'mockSvgPathContent';
  let mockGraphData;
  let areaChart;
  let spriteSpy;

  beforeEach(() => {
    const store = createStore();

    store.commit(`monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`, MonitoringMock.data);
    store.commit(`monitoringDashboard/${types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS}`, deploymentData);

    [mockGraphData] = store.state.monitoringDashboard.groups[0].metrics;

    areaChart = shallowMount(Area, {
      propsData: {
        graphData: mockGraphData,
        containerWidth: 0,
        deploymentData: store.state.monitoringDashboard.deploymentData,
      },
      slots: {
        default: mockWidgets,
      },
    });

    spriteSpy = spyOnDependency(Area, 'getSvgIconPathContent').and.callFake(
      () => new Promise(resolve => resolve(mockSvgPathContent)),
    );
  });

  afterEach(() => {
    areaChart.destroy();
  });

  it('renders chart title', () => {
    expect(areaChart.find({ ref: 'graphTitle' }).text()).toBe(mockGraphData.title);
  });

  it('contains graph widgets from slot', () => {
    expect(areaChart.find({ ref: 'graphWidgets' }).text()).toBe(mockWidgets);
  });

  describe('wrapped components', () => {
    describe('GitLab UI area chart', () => {
      let glAreaChart;

      beforeEach(() => {
        glAreaChart = areaChart.find(GlAreaChart);
      });

      it('is a Vue instance', () => {
        expect(glAreaChart.isVueInstance()).toBe(true);
      });

      it('receives data properties needed for proper chart render', () => {
        const props = glAreaChart.props();

        expect(props.data).toBe(areaChart.vm.chartData);
        expect(props.option).toBe(areaChart.vm.chartOptions);
        expect(props.formatTooltipText).toBe(areaChart.vm.formatTooltipText);
        expect(props.thresholds).toBe(areaChart.vm.thresholds);
      });

      it('recieves a tooltip title', () => {
        const mockTitle = 'mockTitle';
        areaChart.vm.tooltip.title = mockTitle;

        expect(shallowWrapperContainsSlotText(glAreaChart, 'tooltipTitle', mockTitle)).toBe(true);
      });

      describe('when tooltip is showing deployment data', () => {
        beforeEach(() => {
          areaChart.vm.tooltip.isDeployment = true;
        });

        it('uses deployment title', () => {
          expect(shallowWrapperContainsSlotText(glAreaChart, 'tooltipTitle', 'Deployed')).toBe(
            true,
          );
        });

        it('renders commit sha in tooltip content', () => {
          const mockSha = 'mockSha';
          areaChart.vm.tooltip.sha = mockSha;

          expect(shallowWrapperContainsSlotText(glAreaChart, 'tooltipContent', mockSha)).toBe(true);
        });
      });
    });
  });

  describe('methods', () => {
    describe('formatTooltipText', () => {
      const mockDate = deploymentData[0].created_at;
      const generateSeriesData = type => ({
        seriesData: [
          {
            seriesName: areaChart.vm.chartData[0].name,
            componentSubType: type,
            value: [mockDate, 5.55555],
            seriesIndex: 0,
          },
        ],
        value: mockDate,
      });

      describe('when series is of line type', () => {
        beforeEach(() => {
          areaChart.vm.formatTooltipText(generateSeriesData('line'));
        });

        it('formats tooltip title', () => {
          expect(areaChart.vm.tooltip.title).toBe('31 May 2017, 9:23PM');
        });

        it('formats tooltip content', () => {
          const name = 'Core Usage';
          const value = '5.556';
          const seriesLabel = areaChart.find(GlChartSeriesLabel);

          expect(seriesLabel.vm.color).toBe('');
          expect(shallowWrapperContainsSlotText(seriesLabel, 'default', name)).toBe(true);
          expect(areaChart.vm.tooltip.content).toEqual([{ name, value, color: undefined }]);
          expect(
            shallowWrapperContainsSlotText(areaChart.find(GlAreaChart), 'tooltipContent', value),
          ).toBe(true);
        });
      });

      describe('when series is of scatter type', () => {
        beforeEach(() => {
          areaChart.vm.formatTooltipText(generateSeriesData('scatter'));
        });

        it('formats tooltip title', () => {
          expect(areaChart.vm.tooltip.title).toBe('31 May 2017, 9:23PM');
        });

        it('formats tooltip sha', () => {
          expect(areaChart.vm.tooltip.sha).toBe('f5bcd1d9');
        });
      });
    });

    describe('setSvg', () => {
      const mockSvgName = 'mockSvgName';

      beforeEach(() => {
        areaChart.vm.setSvg(mockSvgName);
      });

      it('gets svg path content', () => {
        expect(spriteSpy).toHaveBeenCalledWith(mockSvgName);
      });

      it('sets svg path content', done => {
        areaChart.vm.$nextTick(() => {
          expect(areaChart.vm.svgs[mockSvgName]).toBe(`path://${mockSvgPathContent}`);
          done();
        });
      });
    });

    describe('onResize', () => {
      const mockWidth = 233;

      beforeEach(() => {
        spyOn(Element.prototype, 'getBoundingClientRect').and.callFake(() => ({
          width: mockWidth,
        }));
        areaChart.vm.onResize();
      });

      it('sets area chart width', () => {
        expect(areaChart.vm.width).toBe(mockWidth);
      });
    });
  });

  describe('computed', () => {
    describe('chartData', () => {
      let chartData;
      const seriesData = () => chartData[0];

      beforeEach(() => {
        ({ chartData } = areaChart.vm);
      });

      it('utilizes all data points', () => {
        expect(chartData.length).toBe(1);
        expect(seriesData().data.length).toBe(297);
      });

      it('creates valid data', () => {
        const { data } = seriesData();

        expect(
          data.filter(([time, value]) => new Date(time).getTime() > 0 && typeof value === 'number')
            .length,
        ).toBe(data.length);
      });

      it('formats line width correctly', () => {
        expect(chartData[0].lineStyle.width).toBe(2);
      });
    });

    describe('chartOptions', () => {
      describe('yAxis formatter', () => {
        let format;

        beforeEach(() => {
          format = areaChart.vm.chartOptions.yAxis.axisLabel.formatter;
        });

        it('rounds to 3 decimal places', () => {
          expect(format(0.88888)).toBe('0.889');
        });
      });
    });

    describe('scatterSeries', () => {
      it('utilizes deployment data', () => {
        expect(areaChart.vm.scatterSeries.data).toEqual([
          ['2017-05-31T21:23:37.881Z', 0],
          ['2017-05-30T20:08:04.629Z', 0],
          ['2017-05-30T17:42:38.409Z', 0],
        ]);
      });
    });

    describe('yAxisLabel', () => {
      it('constructs a label for the chart y-axis', () => {
        expect(areaChart.vm.yAxisLabel).toBe('CPU');
      });
    });
  });
});
