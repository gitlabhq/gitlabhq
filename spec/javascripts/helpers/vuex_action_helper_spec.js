import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import testAction from './vuex_action_helper';

describe('VueX test helper (testAction)', () => {
  let originalExpect;
  let assertion;
  let mock;
  const noop = () => {};

  beforeAll(() => {
    mock = new MockAdapter(axios);
    /*
    In order to test the helper properly, we need to overwrite the jasmine `expect` helper.
    We test that the testAction helper properly passes the dispatched actions/committed mutations
    to the jasmine helper.
     */
    originalExpect = expect;
    assertion = null;
    global.expect = actual => ({
      toEqual: () => {
        originalExpect(actual).toEqual(assertion);
      },
    });
  });

  afterAll(() => {
    mock.restore();
    global.expect = originalExpect;
  });

  it('should properly pass on state and payload', () => {
    const exampleState = { FOO: 12, BAR: 3 };
    const examplePayload = { BAZ: 73, BIZ: 55 };

    const action = ({ state }, payload) => {
      originalExpect(state).toEqual(exampleState);
      originalExpect(payload).toEqual(examplePayload);
    };

    assertion = { mutations: [], actions: [] };

    testAction(action, examplePayload, exampleState);
  });

  describe('should work with synchronous actions', () => {
    it('committing mutation', () => {
      const action = ({ commit }) => {
        commit('MUTATION');
      };

      assertion = { mutations: [{ type: 'MUTATION' }], actions: [] };

      testAction(action, null, {}, assertion.mutations, assertion.actions, noop);
    });

    it('dispatching action', () => {
      const action = ({ dispatch }) => {
        dispatch('ACTION');
      };

      assertion = { actions: [{ type: 'ACTION' }], mutations: [] };

      testAction(action, null, {}, assertion.mutations, assertion.actions, noop);
    });

    it('work with jasmine done once finished', done => {
      assertion = { mutations: [], actions: [] };

      testAction(noop, null, {}, assertion.mutations, assertion.actions, done);
    });

    it('provide promise interface', done => {
      assertion = { mutations: [], actions: [] };

      testAction(noop, null, {}, assertion.mutations, assertion.actions)
        .then(done)
        .catch(done.fail);
    });
  });

  describe('should work with promise based actions (fetch action)', () => {
    let lastError;
    const data = { FOO: 'BAR' };

    const promiseAction = ({ commit, dispatch }) => {
      dispatch('ACTION');

      return axios
        .get(TEST_HOST)
        .catch(error => {
          commit('ERROR');
          lastError = error;
          throw error;
        })
        .then(() => {
          commit('SUCCESS');
          return data;
        });
    };

    beforeEach(() => {
      lastError = null;
    });

    it('work with jasmine done once finished', done => {
      mock.onGet(TEST_HOST).replyOnce(200, 42);

      assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

      testAction(promiseAction, null, {}, assertion.mutations, assertion.actions, done);
    });

    it('return original data of successful promise while checking actions/mutations', done => {
      mock.onGet(TEST_HOST).replyOnce(200, 42);

      assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

      testAction(promiseAction, null, {}, assertion.mutations, assertion.actions)
        .then(res => {
          originalExpect(res).toEqual(data);
          done();
        })
        .catch(done.fail);
    });

    it('return original error of rejected promise while checking actions/mutations', done => {
      mock.onGet(TEST_HOST).replyOnce(500, '');

      assertion = { mutations: [{ type: 'ERROR' }], actions: [{ type: 'ACTION' }] };

      testAction(promiseAction, null, {}, assertion.mutations, assertion.actions)
        .then(done.fail)
        .catch(error => {
          originalExpect(error).toBe(lastError);
          done();
        });
    });
  });

  it('should work with async actions not returning promises', done => {
    const data = { FOO: 'BAR' };

    const promiseAction = ({ commit, dispatch }) => {
      dispatch('ACTION');

      axios
        .get(TEST_HOST)
        .then(() => {
          commit('SUCCESS');
          return data;
        })
        .catch(error => {
          commit('ERROR');
          throw error;
        });
    };

    mock.onGet(TEST_HOST).replyOnce(200, 42);

    assertion = { mutations: [{ type: 'SUCCESS' }], actions: [{ type: 'ACTION' }] };

    testAction(promiseAction, null, {}, assertion.mutations, assertion.actions, done);
  });
});
