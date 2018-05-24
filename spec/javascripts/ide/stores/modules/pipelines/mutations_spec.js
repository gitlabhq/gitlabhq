import mutations from '~/ide/stores/modules/pipelines/mutations';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import { pipelines, jobs } from '../../../mock_data';

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
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](mockedState, pipelines[0]);

      expect(mockedState.isLoadingPipeline).toBe(false);
    });

    it('sets latestPipeline', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](mockedState, pipelines[0]);

      expect(mockedState.latestPipeline).toEqual({
        id: pipelines[0].id,
        status: pipelines[0].status,
      });
    });

    it('does not set latest pipeline if pipeline is null', () => {
      mutations[types.RECEIVE_LASTEST_PIPELINE_SUCCESS](mockedState, null);

      expect(mockedState.latestPipeline).toEqual(null);
    });
  });

  describe(types.REQUEST_JOBS, () => {
    it('sets jobs loading to true', () => {
      mutations[types.REQUEST_JOBS](mockedState);

      expect(mockedState.isLoadingJobs).toBe(true);
    });
  });

  describe(types.RECEIVE_JOBS_ERROR, () => {
    it('sets jobs loading to false', () => {
      mutations[types.RECEIVE_JOBS_ERROR](mockedState);

      expect(mockedState.isLoadingJobs).toBe(false);
    });
  });

  describe(types.RECEIVE_JOBS_SUCCESS, () => {
    it('sets jobs loading to false on success', () => {
      mutations[types.RECEIVE_JOBS_SUCCESS](mockedState, jobs);

      expect(mockedState.isLoadingJobs).toBe(false);
    });

    it('sets stages', () => {
      mutations[types.RECEIVE_JOBS_SUCCESS](mockedState, jobs);

      expect(mockedState.stages.length).toBe(2);
      expect(mockedState.stages).toEqual([
        {
          title: 'test',
          jobs: jasmine.anything(),
        },
        {
          title: 'build',
          jobs: jasmine.anything(),
        },
      ]);
    });

    it('sets jobs in stages', () => {
      mutations[types.RECEIVE_JOBS_SUCCESS](mockedState, jobs);

      expect(mockedState.stages[0].jobs.length).toBe(3);
      expect(mockedState.stages[1].jobs.length).toBe(1);
      expect(mockedState.stages).toEqual([
        {
          title: jasmine.anything(),
          jobs: jobs.filter(job => job.stage === 'test').map(job => ({
            id: job.id,
            name: job.name,
            status: job.status,
            stage: job.stage,
            duration: job.duration,
          })),
        },
        {
          title: jasmine.anything(),
          jobs: jobs.filter(job => job.stage === 'build').map(job => ({
            id: job.id,
            name: job.name,
            status: job.status,
            stage: job.stage,
            duration: job.duration,
          })),
        },
      ]);
    });
  });
});
