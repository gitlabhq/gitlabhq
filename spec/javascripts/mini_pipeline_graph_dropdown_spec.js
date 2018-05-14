/* eslint-disable no-new */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';
import timeoutPromise from './helpers/set_timeout_promise_helper';

describe('Mini Pipeline Graph Dropdown', () => {
  preloadFixtures('static/mini_dropdown_graph.html.raw');

  beforeEach(() => {
    loadFixtures('static/mini_dropdown_graph.html.raw');
  });

  describe('When is initialized', () => {
    it('should initialize without errors when no options are given', () => {
      const miniPipelineGraph = new MiniPipelineGraph();

      expect(miniPipelineGraph.dropdownListSelector).toEqual('.js-builds-dropdown-container');
    });

    it('should set the container as the given prop', () => {
      const container = '.foo';

      const miniPipelineGraph = new MiniPipelineGraph({ container });

      expect(miniPipelineGraph.container).toEqual(container);
    });
  });

  describe('When dropdown is clicked', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should call getBuildsList', () => {
      const getBuildsListSpy = spyOn(
        MiniPipelineGraph.prototype,
        'getBuildsList',
      ).and.callFake(function () {});

      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      expect(getBuildsListSpy).toHaveBeenCalled();
    });

    it('should make a request to the endpoint provided in the html', () => {
      const ajaxSpy = spyOn(axios, 'get').and.callThrough();

      mock.onGet('foobar').reply(200, {
        html: '',
      });

      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();
      expect(ajaxSpy.calls.allArgs()[0][0]).toEqual('foobar');
    });

    it('should not close when user uses cmd/ctrl + click', (done) => {
      mock.onGet('foobar').reply(200, {
        html: `<li>
          <a class="mini-pipeline-graph-dropdown-item" href="#">
            <span class="ci-status-icon ci-status-icon-failed"></span>
            <span class="ci-build-text">build</span>
          </a>
          <a class="ci-action-icon-wrapper js-ci-action-icon" href="#"></a>
        </li>`,
      });
      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      timeoutPromise()
        .then(() => {
          document.querySelector('a.mini-pipeline-graph-dropdown-item').click();
        })
        .then(timeoutPromise)
        .then(() => {
          expect($('.js-builds-dropdown-list').is(':visible')).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should close the dropdown when request returns an error', (done) => {
      mock.onGet('foobar').networkError();

      new MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

      document.querySelector('.js-builds-dropdown-button').click();

      setTimeout(() => {
        expect($('.js-builds-dropdown-tests .dropdown').hasClass('open')).toEqual(false);
        done();
      });
    });
  });
});
