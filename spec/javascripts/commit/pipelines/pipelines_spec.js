import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import pipelinesTable from '~/commit/pipelines/pipelines_table.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Pipelines table in Commits and Merge requests', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';
  let pipeline;
  let PipelinesTable;
  let mock;
  let vm;

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    mock = new MockAdapter(axios);

    const pipelines = getJSONFixture(jsonFixtureName).pipelines;

    PipelinesTable = Vue.extend(pipelinesTable);
    pipeline = pipelines.find(p => p.user !== null && p.commit !== null);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  describe('successful request', () => {
    describe('without pipelines', () => {
      beforeEach(function () {
        mock.onGet('endpoint.json').reply(200, []);

        vm = mountComponent(PipelinesTable, {
          endpoint: 'endpoint.json',
          helpPagePath: 'foo',
          emptyStateSvgPath: 'foo',
          errorStateSvgPath: 'foo',
          autoDevopsHelpPath: 'foo',
        });
      });

      it('should render the empty state', function (done) {
        setTimeout(() => {
          expect(vm.$el.querySelector('.empty-state')).toBeDefined();
          expect(vm.$el.querySelector('.realtime-loading')).toBe(null);
          expect(vm.$el.querySelector('.js-pipelines-error-state')).toBe(null);
          done();
        }, 0);
      });
    });

    describe('with pipelines', () => {
      beforeEach(() => {
        mock.onGet('endpoint.json').reply(200, [pipeline]);
        vm = mountComponent(PipelinesTable, {
          endpoint: 'endpoint.json',
          helpPagePath: 'foo',
          emptyStateSvgPath: 'foo',
          errorStateSvgPath: 'foo',
          autoDevopsHelpPath: 'foo',
        });
      });

      it('should render a table with the received pipelines', (done) => {
        setTimeout(() => {
          expect(vm.$el.querySelectorAll('.ci-table .commit').length).toEqual(1);
          expect(vm.$el.querySelector('.realtime-loading')).toBe(null);
          expect(vm.$el.querySelector('.empty-state')).toBe(null);
          expect(vm.$el.querySelector('.js-pipelines-error-state')).toBe(null);
          done();
        }, 0);
      });
    });

    describe('pipeline badge counts', () => {
      beforeEach(() => {
        mock.onGet('endpoint.json').reply(200, [pipeline]);
      });

      it('should receive update-pipelines-count event', (done) => {
        const element = document.createElement('div');
        document.body.appendChild(element);

        element.addEventListener('update-pipelines-count', (event) => {
          expect(event.detail.pipelines).toEqual([pipeline]);
          done();
        });

        vm = mountComponent(PipelinesTable, {
          endpoint: 'endpoint.json',
          helpPagePath: 'foo',
          emptyStateSvgPath: 'foo',
          errorStateSvgPath: 'foo',
          autoDevopsHelpPath: 'foo',
        });

        element.appendChild(vm.$el);
      });
    });
  });

  describe('unsuccessfull request', () => {
    beforeEach(() => {
      mock.onGet('endpoint.json').reply(500, []);

      vm = mountComponent(PipelinesTable, {
        endpoint: 'endpoint.json',
        helpPagePath: 'foo',
        emptyStateSvgPath: 'foo',
        errorStateSvgPath: 'foo',
        autoDevopsHelpPath: 'foo',
      });
    });

    it('should render error state', function (done) {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-pipelines-error-state')).toBeDefined();
        expect(vm.$el.querySelector('.realtime-loading')).toBe(null);
        expect(vm.$el.querySelector('.js-empty-state')).toBe(null);
        expect(vm.$el.querySelector('.ci-table')).toBe(null);
        done();
      }, 0);
    });
  });
});
