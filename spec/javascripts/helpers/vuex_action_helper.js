/* eslint-disable */

export const testWithDispatch = (action, payload, state, expectedDispatch, done) => {
  let count = 0;

  // mock commit
  const dispatch = (type, payload) => {
    const dispatch = expectedDispatch[count];

    try {
      expect(dispatch.type).toEqual(type);
      if (payload !== null) {
        expect(dispatch.payload).toEqual(payload);
      }
    } catch (error) {
      done.fail(error);
    }

    count++;
    if (count >= expectedDispatch.length) {
      done();
    }
  };

  // call the action with mocked store and arguments
  action({ dispatch, state }, payload);

  // check if no mutations should have been dispatched
  if (expectedDispatch.length === 0) {
    expect(count).to.equal(0);
    done();
  }
};

/**
 * helper for testing action with expected mutations
 * https://vuex.vuejs.org/en/testing.html
 */
export default (action, payload, state, expectedMutations, done) => {
  let count = 0;

  // mock commit
  const commit = (type, payload) => {
    const mutation = expectedMutations[count];

    try {
      expect(mutation.type).toEqual(type);
      if (payload !== null) {
        expect(mutation.payload).toEqual(payload);
      }
    } catch (error) {
      if (done) {
        done.fail(error);
      }
    }

    count++;
    if (count >= expectedMutations.length && done) {
      done();
    }
  };

  // call the action with mocked store and arguments
  return action({ commit, state }, payload);

  // check if no mutations should have been dispatched
  if (expectedMutations.length === 0) {
    expect(count).to.equal(0);

    if (done) {
      done();
    }
  }
};
