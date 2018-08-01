import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import state from '~/reports/store/state';
import component from '~/reports/components/grouped_test_reports_app.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import newFailedTestReports from '../mock_data/new_failures_report.json';
import successTestReports from '../mock_data/no_failures_report.json';
import mixedResultsTestReports from '../mock_data/new_and_fixed_failures_report.json';

describe('Grouped Test Reports App', () => {
  let vm;
  let mock;
  const Component = Vue.extend(component);

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$store.replaceState(state());
    vm.$destroy();
    mock.restore();
  });

  describe('with success result', () => {
    beforeEach(() => {
      mock.onGet('test_results.json').reply(200, successTestReports, {});
      vm = mountComponent(Component, {
        endpoint: 'test_results.json',
      });
    });

    it('renders success summary text', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Test summary contained no changed test results out of 11 total tests',
        );

        expect(vm.$el.textContent).toContain(
          'rspec:pg found no changed test results out of 8 total tests',
        );
        expect(vm.$el.textContent).toContain(
          'java ant found no changed test results out of 3 total tests',
        );
        done();
      }, 0);
    });
  });

  describe('with 204 result', () => {
    beforeEach(() => {
      mock.onGet('test_results.json').reply(204, {}, {});
      vm = mountComponent(Component, {
        endpoint: 'test_results.json',
      });
    });

    it('renders success summary text', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).not.toBeNull();
        expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Test summary results are being parsed',
        );

        done();
      }, 0);
    });
  });

  describe('with new failed result', () => {
    beforeEach(() => {
      mock.onGet('test_results.json').reply(200, newFailedTestReports, {});
      vm = mountComponent(Component, {
        endpoint: 'test_results.json',
      });
    });

    it('renders failed summary text + new badge', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Test summary contained 2 failed test results out of 11 total tests',
        );

        expect(vm.$el.textContent).toContain(
          'rspec:pg found 2 failed test results out of 8 total tests',
        );
        expect(vm.$el.textContent).toContain('New');
        expect(vm.$el.textContent).toContain(
          'java ant found no changed test results out of 3 total tests',
        );
        done();
      }, 0);
    });
  });

  describe('with mixed results', () => {
    beforeEach(() => {
      mock.onGet('test_results.json').reply(200, mixedResultsTestReports, {});
      vm = mountComponent(Component, {
        endpoint: 'test_results.json',
      });
    });

    it('renders summary text', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Test summary contained 2 failed test results and 2 fixed test results out of 11 total tests',
        );

        expect(vm.$el.textContent).toContain(
          'rspec:pg found 1 failed test result and 2 fixed test results out of 8 total tests',
        );
        expect(vm.$el.textContent).toContain('New');
        expect(vm.$el.textContent).toContain(
          ' java ant found 1 failed test result out of 3 total tests',
        );
        done();
      }, 0);
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mock.onGet('test_results.json').reply(500, {}, {});
      vm = mountComponent(Component, {
        endpoint: 'test_results.json',
      });
    });

    it('renders loading summary text with loading icon', done => {
      setTimeout(() => {
        expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
          'Test summary failed loading results',
        );
        done();
      }, 0);
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      mock.onGet('test_results.json').reply(200, {}, {});
      vm = mountComponent(Component, {
        endpoint: 'test_results.json',
      });
    });

    it('renders loading summary text with loading icon', done => {
      expect(vm.$el.querySelector('.fa-spinner')).not.toBeNull();
      expect(vm.$el.querySelector('.js-code-text').textContent.trim()).toEqual(
        'Test summary results are being parsed',
      );

      setTimeout(() => {
        done();
      }, 0);
    });
  });
});
