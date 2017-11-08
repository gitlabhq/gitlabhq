import { decorateData } from '~/repo/stores/utils';
import state from '~/repo/stores/state';

export const resetStore = (store) => {
  store.replaceState(state());
};

export const file = (name = 'name', id = name, type = '') => decorateData({
  id,
  type,
  icon: 'icon',
  url: 'url',
  name,
  path: name,
});
