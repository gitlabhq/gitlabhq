import PipelineStore from '~/pipelines/stores/pipeline_store';

describe('Pipeline Store', () => {
  let store;

  beforeEach(() => {
    store = new PipelineStore();
  });

  it('should set defaults', () => {
    expect(store.state.pipeline).toEqual({});
  });

  describe('storePipeline', () => {
    it('should store empty object if none is provided', () => {
      store.storePipeline();

      expect(store.state.pipeline).toEqual({});
    });

    it('should store received object', () => {
      store.storePipeline({ foo: 'bar' });
      expect(store.state.pipeline).toEqual({ foo: 'bar' });
    });
  });
});
