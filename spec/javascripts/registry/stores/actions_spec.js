import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/registry/stores/actions';
import * as types from '~/registry/stores/mutation_types';
import state from '~/registry/stores/state';
import { TEST_HOST } from 'spec/test_constants';
import testAction from '../../helpers/vuex_action_helper';
import {
  reposServerResponse,
  registryServerResponse,
  parsedReposServerResponse,
} from '../mock_data';

describe('Actions Registry Store', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('server requests', () => {
    describe('fetchRepos', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, reposServerResponse, {});
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
      let repo;
      beforeEach(() => {
        mockedState.repos = parsedReposServerResponse;
        [, repo] = mockedState.repos;

        mock.onGet(repo.tagsPath).replyOnce(200, registryServerResponse, {});
      });

      it('should set received list', done => {
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

  describe('deleteItem', () => {
    it('should perform DELETE request on destroyPath', done => {
      const destroyPath = `${TEST_HOST}/mygroup/myproject/container_registry/1.json`;
      let deleted = false;
      mock.onDelete(destroyPath).replyOnce(() => {
        deleted = true;
        return [200];
      });
      testAction(
        actions.deleteItem,
        {
          destroyPath,
        },
        mockedState,
      )
        .then(() => {
          expect(mock.history.delete.length).toBe(1);
          expect(deleted).toBe(true);
          done();
        })
        .catch(done.fail);
    });
  });
});
