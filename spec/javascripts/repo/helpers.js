import { decorateData } from '~/ide/stores/utils';
import state from '~/ide/stores/state';
import commitState from '~/ide/stores/modules/commit/state';

export const resetStore = (store) => {
  store.replaceState(state());
  Object.assign(store.state, {
    commit: commitState(),
  });
};

export const file = (name = 'name', id = name, type = '') => decorateData({
  id,
  type,
  icon: 'icon',
  url: 'url',
  name,
  path: name,
  lastCommit: {},
});
