const noop = () => {};

/**
 * Helper for testing action with expected mutations inspired in
 * https://vuex.vuejs.org/en/testing.html
 *
 * @param {Function} action to be tested
 * @param {Object} payload will be provided to the action
 * @param {Object} state will be provided to the action
 * @param {Array} [expectedMutations=[]] mutations expected to be committed
 * @param {Array} [expectedActions=[]] actions expected to be dispatched
 * @param {Function} [done=noop] to be executed after the tests
 * @return {Promise}
 *
 * @example
 * testAction(
 *   actions.actionName, // action
 *   { }, // mocked payload
 *   state, //state
 *   // expected mutations
 *   [
 *    { type: types.MUTATION}
 *    { type: types.MUTATION_1, payload: jasmine.any(Number)}
 *   ],
 *   // expected actions
 *   [
 *    { type: 'actionName', payload: {param: 'foobar'}},
 *    { type: 'actionName1'}
 *   ]
 *   done,
 * );
 *
 * @example
 * testAction(
 *   actions.actionName, // action
 *   { }, // mocked payload
 *   state, //state
 *   [ { type: types.MUTATION} ], // expected mutations
 *   [], // expected actions
 * ).then(done)
 * .catch(done.fail);
 */
export default (
  action,
  payload,
  state,
  expectedMutations = [],
  expectedActions = [],
  done = noop,
) => {
  const mutations = [];
  const actions = [];

  // mock commit
  const commit = (type, mutationPayload) => {
    const mutation = { type };

    if (typeof mutationPayload !== 'undefined') {
      mutation.payload = mutationPayload;
    }

    mutations.push(mutation);
  };

  // mock dispatch
  const dispatch = (type, actionPayload) => {
    const dispatchedAction = { type };

    if (typeof actionPayload !== 'undefined') {
      dispatchedAction.payload = actionPayload;
    }

    actions.push(dispatchedAction);
  };

  const validateResults = () => {
    expect({
      mutations,
      actions,
    }).toEqual({
      mutations: expectedMutations,
      actions: expectedActions,
    });
    done();
  };

  const result = action(
    { commit, state, dispatch, rootState: state, rootGetters: state, getters: state },
    payload,
  );

  return new Promise(setImmediate)
    .then(() => result)
    .catch(error => {
      validateResults();
      throw error;
    })
    .then(data => {
      validateResults();
      return data;
    });
};
