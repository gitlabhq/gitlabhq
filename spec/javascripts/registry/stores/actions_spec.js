import Vue from 'vue';
import VueResource from 'vue-resource';
import _ from 'underscore';
import * as actions from '~/registry/stores/actions';
import * as types from '~/registry/stores/mutation_types';
import testAction from '../../helpers/vuex_action_helper';
import {
  defaultState,
  reposServerResponse,
  registryServerResponse,
  parsedReposServerResponse,
} from '../mock_data';

Vue.use(VueResource);

describe('Actions Registry Store', () => {
  let interceptor;
  let mockedState;

  beforeEach(() => {
    mockedState = defaultState;
  });

  describe('server requests', () => {
    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    describe('fetchRepos', () => {
      beforeEach(() => {
        interceptor = (request, next) => {
          next(
            request.respondWith(JSON.stringify(reposServerResponse), {
              status: 200,
            }),
          );
        };

        Vue.http.interceptors.push(interceptor);
      });

      it('should set receveived repos', done => {
        testAction(
          actions.fetchRepos,
          null,
          mockedState,
          [
            { type: types.TOGGLE_MAIN_LOADING },
            { type: types.TOGGLE_MAIN_LOADING },
            { type: types.SET_REPOS_LIST, payload: reposServerResponse },
          ],
          [],
          done,
        );
      });
    });

    describe('fetchList', () => {
      beforeEach(() => {
        interceptor = (request, next) => {
          next(
            request.respondWith(JSON.stringify(registryServerResponse), {
              status: 200,
            }),
          );
        };

        Vue.http.interceptors.push(interceptor);
      });

      it('should set received list', done => {
        mockedState.repos = parsedReposServerResponse;

        const repo = mockedState.repos[1];

        testAction(
          actions.fetchList,
          { repo },
          mockedState,
          [
            { type: types.TOGGLE_REGISTRY_LIST_LOADING, payload: repo },
            { type: types.TOGGLE_REGISTRY_LIST_LOADING, payload: repo },
            {
              type: types.SET_REGISTRY_LIST,
              payload: {
                repo,
                resp: registryServerResponse,
                headers: jasmine.anything(),
              },
            },
          ],
          [],
          done,
        );
      });
    });
  });

  describe('setMainEndpoint', () => {
    it('should commit set main endpoint', done => {
      testAction(
        actions.setMainEndpoint,
        'endpoint',
        mockedState,
        [{ type: types.SET_MAIN_ENDPOINT, payload: 'endpoint' }],
        [],
        done,
      );
    });
  });

  describe('toggleLoading', () => {
    it('should commit toggle main loading', done => {
      testAction(
        actions.toggleLoading,
        null,
        mockedState,
        [{ type: types.TOGGLE_MAIN_LOADING }],
        [],
        done,
      );
    });
  });
});
