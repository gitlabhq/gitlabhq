import Vue from 'vue';
import _ from 'underscore';
import MonitoringColumn from '~/monitoring/components/monitoring_column.vue';
import eventHub from '~/monitoring/event_hub';
import { deploymentData, singleRowMetrics } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringColumn);

  return new Component({
    propsData,
  });
};

describe('MonitoringColumn', () => {
  beforeEach(() => {
    spyOn(MonitoringColumn.methods, 'formatDeployments').and.callFake(function fakeFormat() {
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
    component.$mount();

    expect(component.$el.querySelector('.text-center').innerText.trim()).toBe(component.columnData.title);
  });

  it('creates a path for the line and area of the graph', (done) => {
    const component = createComponent({
      columnData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });
    component.$mount();

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

  it('should contain a hidden gradient', () => {
    const component = createComponent({
      columnData: singleRowMetrics[0],
      classType: 'col-md-6',
      updateAspectRatio: false,
      deploymentData,
    });
    component.$mount();

    expect(component.$el.querySelector('#shadow-gradient')).not.toBe(null);
  });

  describe('Computed props', () => {
    it('calculateAxisTransform translates an element Y position depending of its height', () => {
      const component = createComponent({
        columnData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const transformedHeight = `${component.height - 100}`;
      expect(component.calculateAxisTransform.indexOf(transformedHeight))
        .not.toEqual(-1);
    });

    it('calculateViewBox gets a width and height property based on the DOM size of the element', () => {
      const component = createComponent({
        columnData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const viewBoxArray = component.calculateViewBox.split(' ');
      expect(typeof component.calculateViewBox).toEqual('string');
      expect(viewBoxArray[2]).toEqual(component.width.toString());
      expect(viewBoxArray[3]).toEqual(component.height.toString());
    });

    it('calculateInnerViewBox gets a width - 150 and height property based on the DOM size of the element', () => {
      const component = createComponent({
        columnData: singleRowMetrics[0],
        classType: 'col-md-6',
        updateAspectRatio: false,
        deploymentData,
      });

      const viewBoxArray = component.calculateInnerViewBox.split(' ');
      const adjustedWidth = `${component.width - 150}`;
      expect(typeof component.calculateInnerViewBox).toEqual('string');
      expect(viewBoxArray[2]).toEqual(adjustedWidth);
      expect(viewBoxArray[3]).toEqual(component.height.toString());
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
    component.$mount();

    component.updateAspectRatio = true;
    Vue.nextTick(() => {
      expect(eventHub.$emit).toHaveBeenCalled();
      done();
    });
  });
});
