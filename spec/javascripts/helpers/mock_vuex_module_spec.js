import mockVuexModule from './mock_vuex_module';

const TEST_FOO_MODULE = {
  state: {
    a: { b: 123 },
    c: false,
  },
  actions: {
    doFoo: () => {},
    doBar: () => {},
  },
};

const TEST_BAR_MODULE = {
  state: {
    d: { e: 'f' },
    g: null,
  },
  actions: {
    doTheHustle: () => {},
  },
};

describe('mock_vuex_module', () => {
  it('clones state', () => {
    const opt = TEST_FOO_MODULE;

    const mock = mockVuexModule(opt);

    expect(mock.state).toEqual(opt.state);
    expect(mock.state).not.toBe(opt.state);
    expect(mock.state.a).not.toBe(opt.state.a);
  });

  it('creates spies on actions', () => {
    const opt = TEST_FOO_MODULE;
    const actionKeys = Object.keys(opt.actions);

    const mock = mockVuexModule(opt);
    const spyKeys = actionKeys.filter(key => jasmine.isSpy(mock.actions[key]));

    expect(spyKeys).toEqual(actionKeys);
  });

  it('mocks inner modules', () => {
    const opt = {
      state: {},
      modules: {
        foo: TEST_FOO_MODULE,
        bar: TEST_BAR_MODULE,
      },
    };

    const mock = mockVuexModule(opt);

    expect(mock.modules.foo.state).toEqual(opt.modules.foo.state);
    expect(mock.modules.foo.state).not.toBe(opt.modules.foo.state);
    expect(Object.values(mock.modules.bar.actions).every(jasmine.isSpy)).toBe(true);
  });
});
