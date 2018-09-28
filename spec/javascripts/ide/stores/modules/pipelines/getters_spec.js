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
});
