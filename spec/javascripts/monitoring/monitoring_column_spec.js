import Vue from 'vue';
import _ from 'underscore';
import MonitoringColumn from '~/monitoring/components/monitoring_column.vue';
import MonitoringMixins from '~/monitoring/mixins/monitoring_mixins';
import eventHub from '~/monitoring/event_hub';
import { deploymentData, singleRowMetrics } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringColumn);

  return new Component({
    propsData,
  }).$mount();
};

describe('MonitoringColumn', () => {
  beforeEach(() => {
    spyOn(MonitoringMixins.methods, 'formatDeployments').and.callFake(function fakeFormat() {
      return {};
    });
  });

  it('has a title', () => {
    const component = createComponent({
      columnData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.$el.querySelector('.text-center').innerText.trim()).toBe(component.columnData.title);
  });

  it('creates a path for the line and area of the graph', (done) => {
    const component = createComponent({
      columnData: singleRowMetrics[0],
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
        columnData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const transformedHeight = `${component.height - 100}`;
      expect(component.axisTransform.indexOf(transformedHeight))
        .not.toEqual(-1);
    });

    it('outterViewBox gets a width and height property based on the DOM size of the element', () => {
      const component = createComponent({
        columnData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const viewBoxArray = component.outterViewBox.split(' ');
      expect(typeof component.outterViewBox).toEqual('string');
      expect(viewBoxArray[2]).toEqual(component.width.toString());
      expect(viewBoxArray[3]).toEqual(component.height.toString());
    });

    it('innerViewBox gets a width - 150 and height property based on the DOM size of the element', () => {
      const component = createComponent({
        columnData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const viewBoxArray = component.innerViewBox.split(' ');
      expect(typeof component.innerViewBox).toEqual('string');
      // This is because the viewport doesn't exist on phantomjs
      expect(viewBoxArray[2]).toEqual('0');
      expect(viewBoxArray[3]).toEqual('0');
    });
  });

  it('sends an event to the eventhub when it has finished resizing', (done) => {
    const component = createComponent({
      columnData: singleRowMetrics[0],
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
});
