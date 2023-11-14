import Vuex from 'vuex'; // eslint-disable-line no-restricted-imports

const createVuexStore = (store) => new Vuex.Store(store);

/*
 * Story decorator for injecting a Vuex store
 */
export const withVuexStore = (story, context) => {
  Object.assign(context, { createVuexStore });
  return {
    components: {
      story,
    },
    template: `<story />`,
  };
};
