import Vue from 'vue';
import _ from 'underscore';
import Graph from '~/monitoring/components/graph.vue';
import MonitoringMixins from '~/monitoring/mixins/monitoring_mixins';
import eventHub from '~/monitoring/event_hub';
import { deploymentData, singleRowMetrics } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(Graph);

  return new Component({
    propsData,
  }).$mount();
};

describe('Graph', () => {
  beforeEach(() => {
    spyOn(MonitoringMixins.methods, 'formatDeployments').and.returnValue({});
  });

  it('has a title', () => {
    const component = createComponent({
      graphData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.$el.querySelector('.text-center').innerText.trim()).toBe(component.graphData.title);
  });

  it('creates a path for the line and area of the graph', (done) => {
    const component = createComponent({
      graphData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });

    Vue.nextTick(() => {
      expect(component.area).toBeDefined();
      expect(component.line).toBeDefined();
      expect(typeof component.area).toEqual('string');
      expect(typeof component.line).toEqual('string');
      expect(_.isFunction(component.xScale)).toBe(true);
      expect(_.isFunction(component.yScale)).toBe(true);
      done();
    });
  });

  describe('Computed props', () => {
    it('axisTransform translates an element Y position depending of its height', () => {
      const component = createComponent({
        graphData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const transformedHeight = `${component.graphHeight - 100}`;
      expect(component.axisTransform.indexOf(transformedHeight))
        .not.toEqual(-1);
    });

    it('outterViewBox gets a width and height property based on the DOM size of the element', () => {
      const component = createComponent({
        graphData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const viewBoxArray = component.outterViewBox.split(' ');
      expect(typeof component.outterViewBox).toEqual('string');
      expect(viewBoxArray[2]).toEqual(component.graphWidth.toString());
      expect(viewBoxArray[3]).toEqual(component.graphHeight.toString());
    });
  });

  it('sends an event to the eventhub when it has finished resizing', (done) => {
    const component = createComponent({
      graphData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });
    spyOn(eventHub, '$emit');

    component.updateAspectRatio = true;
    Vue.nextTick(() => {
      expect(eventHub.$emit).toHaveBeenCalled();
      done();
    });
  });

  it('has a title for the y-axis and the chart legend that comes from the backend', () => {
    const component = createComponent({
      graphData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.yAxisLabel).toEqual(component.graphData.y_label);
    expect(component.legendTitle).toEqual(component.graphData.queries[0].label);
  });
});
