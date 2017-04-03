import Vue from 'vue';
import pipelinesTableComp from '~/vue_shared/components/pipelines_table';
import '~/lib/utils/datetime_utility';
import pipeline from '../../commit/pipelines/mock_data';

describe('Pipelines Table', () => {
  let PipelinesTableComponent;

  beforeEach(() => {
    PipelinesTableComponent = Vue.extend(pipelinesTableComp);
  });

  describe('table', () => {
    let component;
    beforeEach(() => {
      component = new PipelinesTableComponent({
        propsData: {
          pipelines: [],
          service: {},
        },
      }).$mount();
    });

    afterEach(() => {
      component.$destroy();
    });

    it('should render a table', () => {
      expect(component.$el).toEqual('TABLE');
    });

    it('should render table head with correct columns', () => {
      expect(component.$el.querySelector('th.js-pipeline-status').textContent).toEqual('Status');
      expect(component.$el.querySelector('th.js-pipeline-info').textContent).toEqual('Pipeline');
      expect(component.$el.querySelector('th.js-pipeline-commit').textContent).toEqual('Commit');
      expect(component.$el.querySelector('th.js-pipeline-stages').textContent).toEqual('Stages');
      expect(component.$el.querySelector('th.js-pipeline-date').textContent).toEqual('');
      expect(component.$el.querySelector('th.js-pipeline-actions').textContent).toEqual('');
    });
  });

  describe('without data', () => {
    it('should render an empty table', () => {
      const component = new PipelinesTableComponent({
        propsData: {
          pipelines: [],
          service: {},
        },
      }).$mount();
      expect(component.$el.querySelectorAll('tbody tr').length).toEqual(0);
    });
  });

  describe('with data', () => {
    it('should render rows', () => {
      const component = new PipelinesTableComponent({
        el: document.querySelector('.test-dom-element'),
        propsData: {
          pipelines: [pipeline],
          service: {},
        },
      }).$mount();

      expect(component.$el.querySelectorAll('tbody tr').length).toEqual(1);
    });
  });
});
