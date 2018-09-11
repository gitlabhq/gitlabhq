/**
 * Creates a mock of the given Vuex constructor options.
 *
 * Use this on the options passed to `new Vue.Store` to:
 *
 * 1. Deeply clone `state`
 * 2. Create spies on `actions`
 * 3. Recursively call this function on `modules`
 *
 * __Example Usage:__
 *
 * ```
 * import fooModule from 'foo/store/module';
 * import barModule from 'bar/store/module';
 *
 * new Vue.Store(mockVuexModule({
 *   modules: {
 *     foo: fooModule,
 *     bar: barModule,
 *   }
 * }))
 * ```
 */
export default function mockVuexModule(store) {
  const stateClone = store.state && JSON.parse(JSON.stringify(store.state));
  const actionsMocks = store.actions && jasmine.createSpyObj('actions', store.actions);
  const modulesMocks = store.modules && Object.keys(store.modules)
    .filter(key => store.modules[key])
    .reduce((acc, key) => Object.assign(acc, {
      [key]: mockVuexModule(store.modules[key]),
    }), {});

  return {
    ...store,
    state: stateClone,
    actions: actionsMocks,
    modules: modulesMocks,
  };
}
