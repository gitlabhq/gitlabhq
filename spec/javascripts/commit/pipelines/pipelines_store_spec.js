require('~commit/pipelines/pipelines_store');

describe('Store', () => {
  const store = gl.commits.pipelines.PipelinesStore;

  beforeEach(() => {
    store.create();
  });

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

    store.store(pipelines);

    expect(store.state.pipelines.length).toBe(pipelines.length);
  });
});
