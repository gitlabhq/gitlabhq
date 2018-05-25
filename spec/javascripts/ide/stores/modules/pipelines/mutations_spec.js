import mutations from '~/ide/stores/modules/pipelines/mutations';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import { fullPipelinesResponse, stages } from '../../../mock_data';

describe('IDE pipelines mutations', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe(types.REQUEST_LATEST_PIPELINE, () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_LATEST_PIPELINE](mockedState);

      expect(mockedState.isLoadingPipeline).toBe(true);
    });
  });

  describe(types.RECEIVE_LASTEST_PIPELINE_ERROR, () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_ERROR](mockedState);

      expect(mockedState.isLoadingPipeline).toBe(false);
    });
  });

  describe(types.RECEIVE_LASTEST_PIPELINE_SUCCESS, () => {
    it('sets loading to false on success', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](
        mockedState,
        fullPipelinesResponse.data.pipelines[0],
      );

      expect(mockedState.isLoadingPipeline).toBe(false);
    });

    it('sets latestPipeline', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](
        mockedState,
        fullPipelinesResponse.data.pipelines[0],
      );

      expect(mockedState.latestPipeline).toEqual({
        id: '51',
        path: 'test',
        commit: { id: '123' },
        details: { status: jasmine.any(Object) },
      });
    });

    it('does not set latest pipeline if pipeline is null', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](mockedState, null);

      expect(mockedState.latestPipeline).toEqual(null);
    });

    it('sets stages', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](
        mockedState,
        fullPipelinesResponse.data.pipelines[0],
      );

      expect(mockedState.stages.length).toBe(2);
      expect(mockedState.stages).toEqual([
        {
          ...stages[0],
          dropdownPath: stages[0].dropdownPath,
          id: 0,
          isCollapsed: false,
          isLoading: false,
          jobs: [],
        },
        {
          ...stages[1],
          dropdownPath: stages[1].dropdownPath,
          id: 1,
          isCollapsed: false,
          isLoading: false,
          jobs: [],
        },
      ]);
    });
  });
});
