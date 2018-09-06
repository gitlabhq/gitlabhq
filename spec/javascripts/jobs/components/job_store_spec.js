import JobStore from '~/jobs/stores/job_store';
import job from '../mock_data';

describe('Job Store', () => {
  let store;

  beforeEach(() => {
    store = new JobStore();
  });

  it('should set defaults', () => {
    expect(store.state.job).toEqual({});
  });

  describe('storeJob', () => {
    it('should store empty object if none is provided', () => {
      store.storeJob();
      expect(store.state.job).toEqual({});
    });

    it('should store provided argument', () => {
      store.storeJob(job);
      expect(store.state.job).toEqual(job);
    });
  });
});
