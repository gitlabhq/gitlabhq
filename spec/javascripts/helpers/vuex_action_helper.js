/**
 * helper for testing action with expected mutations inspired in
 * https://vuex.vuejs.org/en/testing.html
 *
 * @example
 * testAction(
 *   actions.actionName, // action
 *   { }, // mocked response
 *   state, // state
 *   [
 *    { type: types.MUTATION}
 *    { type: types.MUTATION_1, payload: {}}
 *   ], // mutations
 *   [
 *    { type: 'actionName', payload: {}},
 *    { type: 'actionName1', payload: {}}
 *   ] //actions
 *   done,
 * );
 */
export default (action, payload, state, expectedMutations, expectedActions, done) => {
  let mutationsCount = 0;
  let actionsCount = 0;

  // mock commit
  const commit = (type, mutationPayload) => {
    const mutation = expectedMutations[mutationsCount];

    expect(mutation.type).toEqual(type);

    if (mutation.payload) {
      expect(mutation.payload).toEqual(mutationPayload);
    }

    mutationsCount += 1;
    if (mutationsCount >= expectedMutations.length) {
      done();
    }
  };

  // mock dispatch
  const dispatch = (type, actionPayload) => {
    const actionExpected = expectedActions[actionsCount];

    expect(actionExpected.type).toEqual(type);

    if (actionExpected.payload) {
      expect(actionExpected.payload).toEqual(actionPayload);
    }

    actionsCount += 1;
    if (actionsCount >= expectedActions.length) {
      done();
    }
  };

  // call the action with mocked store and arguments
  action({ commit, state, dispatch }, payload);

  // check if no mutations should have been dispatched
  if (expectedMutations.length === 0) {
    expect(mutationsCount).toEqual(0);
    done();
  }

  // check if no mutations should have been dispatched
  if (expectedActions.length === 0) {
    expect(actionsCount).toEqual(0);
    done();
  }
};
