import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import { GlLink } from '@gitlab/ui';
import { GlAreaChart, GlLineChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { shallowWrapperContainsSlotText } from 'spec/helpers/vue_test_utils_helper';
import TimeSeries from '~/monitoring/components/charts/time_series.vue';
import * as types from '~/monitoring/stores/mutation_types';
import { TEST_HOST } from 'spec/test_constants';
import MonitoringMock, { deploymentData, mockProjectPath } from '../mock_data';

describe('Time series component', () => {
  const mockSha = 'mockSha';
  const mockWidgets = 'mockWidgets';
  const mockSvgPathContent = 'mockSvgPathContent';
  const projectPath = `${TEST_HOST}${mockProjectPath}`;
  const commitUrl = `${projectPath}/commit/${mockSha}`;
  let mockGraphData;
  let makeTimeSeriesChart;
  let spriteSpy;
  let store;

  beforeEach(() => {
    store = createStore();
    store.commit(`monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`, MonitoringMock.data);
    store.commit(`monitoringDashboard/${types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS}`, deploymentData);
    store.dispatch('monitoringDashboard/setFeatureFlags', { exportMetricsToCsvEnabled: true });
    [mockGraphData] = store.state.monitoringDashboard.groups[0].metrics;

    makeTimeSeriesChart = (graphData, type) =>
      shallowMount(TimeSeries, {
        propsData: {
          graphData: { ...graphData, type },
          containerWidth: 0,
          deploymentData: store.state.monitoringDashboard.deploymentData,
          projectPath,
        },
        slots: {
          default: mockWidgets,
        },
        sync: false,
        store,
      });

    spriteSpy = spyOnDependency(TimeSeries, 'getSvgIconPathContent').and.callFake(
      () => new Promise(resolve => resolve(mockSvgPathContent)),
    );
  });

  describe('general functions', () => {
    let timeSeriesChart;

    beforeEach(() => {
      timeSeriesChart = makeTimeSeriesChart(mockGraphData, 'area-chart');
    });

    it('renders chart title', () => {
      expect(timeSeriesChart.find('.js-graph-title').text()).toBe(mockGraphData.title);
    });

    it('contains graph widgets from slot', () => {
      expect(timeSeriesChart.find('.js-graph-widgets').text()).toBe(mockWidgets);
    });

    describe('when exportMetricsToCsvEnabled is disabled', () => {
      beforeEach(() => {
        store.dispatch('monitoringDashboard/setFeatureFlags', { exportMetricsToCsvEnabled: false });
      });

      it('does not render the Download CSV button', done => {
        timeSeriesChart.vm.$nextTick(() => {
          expect(timeSeriesChart.contains('glbutton-stub')).toBe(false);
          done();
        });
      });
    });

    describe('methods', () => {
      describe('formatTooltipText', () => {
        const mockDate = deploymentData[0].created_at;
        const mockCommitUrl = deploymentData[0].commitUrl;
        const generateSeriesData = type => ({
          seriesData: [
            {
              seriesName: timeSeriesChart.vm.chartData[0].name,
              componentSubType: type,
              value: [mockDate, 5.55555],
              seriesIndex: 0,
            },
          ],
          value: mockDate,
        });

        describe('when series is of line type', () => {
          beforeEach(done => {
            timeSeriesChart.vm.formatTooltipText(generateSeriesData('line'));
            timeSeriesChart.vm.$nextTick(done);
          });

          it('formats tooltip title', () => {
            expect(timeSeriesChart.vm.tooltip.title).toBe('31 May 2017, 9:23PM');
          });

          it('formats tooltip content', () => {
            const name = 'Core Usage';
            const value = '5.556';
            const seriesLabel = timeSeriesChart.find(GlChartSeriesLabel);

            expect(seriesLabel.vm.color).toBe('');
            expect(shallowWrapperContainsSlotText(seriesLabel, 'default', name)).toBe(true);
            expect(timeSeriesChart.vm.tooltip.content).toEqual([{ name, value, color: undefined }]);
            expect(
              shallowWrapperContainsSlotText(
                timeSeriesChart.find(GlAreaChart),
                'tooltipContent',
                value,
              ),
            ).toBe(true);
          });
        });

        describe('when series is of scatter type', () => {
          beforeEach(() => {
            timeSeriesChart.vm.formatTooltipText(generateSeriesData('scatter'));
          });

          it('formats tooltip title', () => {
            expect(timeSeriesChart.vm.tooltip.title).toBe('31 May 2017, 9:23PM');
          });

          it('formats tooltip sha', () => {
            expect(timeSeriesChart.vm.tooltip.sha).toBe('f5bcd1d9');
          });

          it('formats tooltip commit url', () => {
            expect(timeSeriesChart.vm.tooltip.commitUrl).toBe(mockCommitUrl);
          });
        });
      });

      describe('setSvg', () => {
        const mockSvgName = 'mockSvgName';

        beforeEach(done => {
          timeSeriesChart.vm.setSvg(mockSvgName);
          timeSeriesChart.vm.$nextTick(done);
        });

        it('gets svg path content', () => {
          expect(spriteSpy).toHaveBeenCalledWith(mockSvgName);
        });

        it('sets svg path content', () => {
          timeSeriesChart.vm.$nextTick(() => {
            expect(timeSeriesChart.vm.svgs[mockSvgName]).toBe(`path://${mockSvgPathContent}`);
          });
        });
      });

      describe('onResize', () => {
        const mockWidth = 233;

        beforeEach(() => {
          spyOn(Element.prototype, 'getBoundingClientRect').and.callFake(() => ({
            width: mockWidth,
          }));
          timeSeriesChart.vm.onResize();
        });

        it('sets area chart width', () => {
          expect(timeSeriesChart.vm.width).toBe(mockWidth);
        });
      });
    });

    describe('computed', () => {
      describe('chartData', () => {
        let chartData;
        const seriesData = () => chartData[0];

        beforeEach(() => {
          ({ chartData } = timeSeriesChart.vm);
        });

        it('utilizes all data points', () => {
          const { values } = mockGraphData.queries[0].result[0];

          expect(chartData.length).toBe(1);
          expect(seriesData().data.length).toBe(values.length);
        });

        it('creates valid data', () => {
          const { data } = seriesData();

          expect(
            data.filter(
              ([time, value]) => new Date(time).getTime() > 0 && typeof value === 'number',
            ).length,
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
            format = timeSeriesChart.vm.chartOptions.yAxis.axisLabel.formatter;
          });

          it('rounds to 3 decimal places', () => {
            expect(format(0.88888)).toBe('0.889');
          });
        });
      });

      describe('scatterSeries', () => {
        it('utilizes deployment data', () => {
          expect(timeSeriesChart.vm.scatterSeries.data).toEqual([
            ['2017-05-31T21:23:37.881Z', 0],
            ['2017-05-30T20:08:04.629Z', 0],
            ['2017-05-30T17:42:38.409Z', 0],
          ]);

          expect(timeSeriesChart.vm.scatterSeries.symbolSize).toBe(14);
        });
      });

      describe('yAxisLabel', () => {
        it('constructs a label for the chart y-axis', () => {
          expect(timeSeriesChart.vm.yAxisLabel).toBe('CPU');
        });
      });

      describe('csvText', () => {
        it('converts data from json to csv', () => {
          const header = `timestamp,${mockGraphData.y_label}`;
          const data = mockGraphData.queries[0].result[0].values;
          const firstRow = `${data[0][0]},${data[0][1]}`;

          expect(timeSeriesChart.vm.csvText).toMatch(`^${header}\r\n${firstRow}`);
        });
      });

      describe('downloadLink', () => {
        it('produces a link to download metrics as csv', () => {
          const link = timeSeriesChart.vm.downloadLink;

          expect(link).toContain('blob:');
        });
      });
    });

    afterEach(() => {
      timeSeriesChart.destroy();
    });
  });

  describe('wrapped components', () => {
    const glChartComponents = [
      {
        chartType: 'area-chart',
        component: GlAreaChart,
      },
      {
        chartType: 'line-chart',
        component: GlLineChart,
      },
    ];

    glChartComponents.forEach(dynamicComponent => {
      describe(`GitLab UI: ${dynamicComponent.chartType}`, () => {
        let timeSeriesAreaChart;
        let glChart;

        beforeEach(done => {
          timeSeriesAreaChart = makeTimeSeriesChart(mockGraphData, dynamicComponent.chartType);
          glChart = timeSeriesAreaChart.find(dynamicComponent.component);
          timeSeriesAreaChart.vm.$nextTick(done);
        });

        it('is a Vue instance', () => {
          expect(glChart.exists()).toBe(true);
          expect(glChart.isVueInstance()).toBe(true);
        });

        it('receives data properties needed for proper chart render', () => {
          const props = glChart.props();

          expect(props.data).toBe(timeSeriesAreaChart.vm.chartData);
          expect(props.option).toBe(timeSeriesAreaChart.vm.chartOptions);
          expect(props.formatTooltipText).toBe(timeSeriesAreaChart.vm.formatTooltipText);
          expect(props.thresholds).toBe(timeSeriesAreaChart.vm.thresholds);
        });

        it('recieves a tooltip title', done => {
          const mockTitle = 'mockTitle';
          timeSeriesAreaChart.vm.tooltip.title = mockTitle;

          timeSeriesAreaChart.vm.$nextTick(() => {
            expect(shallowWrapperContainsSlotText(glChart, 'tooltipTitle', mockTitle)).toBe(true);
            done();
          });
        });

        describe('when tooltip is showing deployment data', () => {
          beforeEach(done => {
            timeSeriesAreaChart.vm.tooltip.isDeployment = true;
            timeSeriesAreaChart.vm.$nextTick(done);
          });

          it('uses deployment title', () => {
            expect(shallowWrapperContainsSlotText(glChart, 'tooltipTitle', 'Deployed')).toBe(true);
          });

          it('renders clickable commit sha in tooltip content', done => {
            timeSeriesAreaChart.vm.tooltip.sha = mockSha;
            timeSeriesAreaChart.vm.tooltip.commitUrl = commitUrl;

            timeSeriesAreaChart.vm.$nextTick(() => {
              const commitLink = timeSeriesAreaChart.find(GlLink);

              expect(shallowWrapperContainsSlotText(commitLink, 'default', mockSha)).toBe(true);
              expect(commitLink.attributes('href')).toEqual(commitUrl);
              done();
            });
          });
        });
      });
    });
  });
});
