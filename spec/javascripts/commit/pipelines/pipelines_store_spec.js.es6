const PipelinesStore = require('~/commit/pipelines/pipelines_store');

describe('Store', () => {
  let store;

  beforeEach(() => {
    store = new PipelinesStore();
  });

  // unregister intervals and event handlers
  afterEach(() => gl.VueRealtimeListener.reset());

  it('should start with a blank state', () => {
    expect(store.state.pipelines.length).toBe(0);
  });

  it('should store an array of pipelines', () => {
    const pipelines = [
      {
        id: '1',
        name: 'pipeline',
      },
      {
        id: '2',
        name: 'pipeline_2',
      },
    ];

    store.storePipelines(pipelines);

    expect(store.state.pipelines.length).toBe(pipelines.length);
  });
});
