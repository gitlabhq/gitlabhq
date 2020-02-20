import state from '~/releases/stores/modules/list/state';

// eslint-disable-next-line import/prefer-default-export
export const resetStore = store => {
  store.replaceState(state());
};
