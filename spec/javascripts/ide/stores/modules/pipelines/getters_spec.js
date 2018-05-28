import * as getters from '~/ide/stores/modules/pipelines/getters';
import state from '~/ide/stores/modules/pipelines/state';

describe('IDE pipeline getters', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('hasLatestPipeline', () => {
    it('returns false when loading is true', () => {
      mockedState.isLoadingPipeline = true;

      expect(getters.hasLatestPipeline(mockedState)).toBe(false);
    });

    it('returns false when pipelines is null', () => {
      mockedState.latestPipeline = null;

      expect(getters.hasLatestPipeline(mockedState)).toBe(false);
    });

    it('returns false when loading is true & pipelines is null', () => {
      mockedState.latestPipeline = null;
      mockedState.isLoadingPipeline = true;

      expect(getters.hasLatestPipeline(mockedState)).toBe(false);
    });

    it('returns true when loading is false & pipelines is an object', () => {
      mockedState.latestPipeline = {
        id: 1,
      };
      mockedState.isLoadingPipeline = false;

      expect(getters.hasLatestPipeline(mockedState)).toBe(true);
    });
  });

  describe('failedJobs', () => {
    it('returns array of failed jobs', () => {
      mockedState.stages = [
        {
          title: 'test',
          jobs: [{ id: 1, status: 'failed' }, { id: 2, status: 'success' }],
        },
        {
          title: 'build',
          jobs: [{ id: 3, status: 'failed' }, { id: 4, status: 'failed' }],
        },
      ];

      expect(getters.failedJobs(mockedState).length).toBe(3);
      expect(getters.failedJobs(mockedState)).toEqual([
        {
          id: 1,
          status: jasmine.anything(),
        },
        {
          id: 3,
          status: jasmine.anything(),
        },
        {
          id: 4,
          status: jasmine.anything(),
        },
      ]);
    });
  });
});
