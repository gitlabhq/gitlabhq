import state from '~/jobs/store/state';
import mutations from '~/jobs/store/mutations';
import * as types from '~/jobs/store/mutation_types';

describe('Jobs Store Mutations', () => {
  let stateCopy;

  const html =
    'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- : Writing /builds/ab89e95b0fa0b9272ea0c797b76908f24d36992630e9325273a4ce3.png<br>I';

  beforeEach(() => {
    stateCopy = state();
  });

  describe('REQUEST_STATUS_FAVICON', () => {
    it('should set fetchingStatusFavicon to true', () => {
      mutations[types.REQUEST_STATUS_FAVICON](stateCopy);
      expect(stateCopy.fetchingStatusFavicon).toEqual(true);
    });
  });

  describe('RECEIVE_STATUS_FAVICON_SUCCESS', () => {
    it('should set fetchingStatusFavicon to false', () => {
      mutations[types.RECEIVE_STATUS_FAVICON_SUCCESS](stateCopy);
      expect(stateCopy.fetchingStatusFavicon).toEqual(false);
    });
  });

  describe('RECEIVE_STATUS_FAVICON_ERROR', () => {
    it('should set fetchingStatusFavicon to false', () => {
      mutations[types.RECEIVE_STATUS_FAVICON_ERROR](stateCopy);
      expect(stateCopy.fetchingStatusFavicon).toEqual(false);
    });
  });

  describe('RECEIVE_TRACE_SUCCESS', () => {
    describe('when trace has state', () => {
      it('sets traceState', () => {
        const stateLog =
          'eyJvZmZzZXQiOjczNDQ1MSwibl9vcGVuX3RhZ3MiOjAsImZnX2NvbG9yIjpudWxsLCJiZ19jb2xvciI6bnVsbCwic3R5bGVfbWFzayI6MH0=';
        mutations[types.RECEIVE_TRACE_SUCCESS](stateCopy, {
          state: stateLog,
        });
        expect(stateCopy.traceState).toEqual(stateLog);
      });
    });

    describe('when traceSize is smaller than the total size', () => {
      it('sets isTraceSizeVisible to true', () => {
        mutations[types.RECEIVE_TRACE_SUCCESS](stateCopy, { total: 51184600, size: 1231 });

        expect(stateCopy.isTraceSizeVisible).toEqual(true);
      });
    });

    describe('when traceSize is bigger than the total size', () => {
      it('sets isTraceSizeVisible to false', () => {
        const copy = Object.assign({}, stateCopy, { traceSize: 5118460, size: 2321312 });

        mutations[types.RECEIVE_TRACE_SUCCESS](copy, { total: 511846 });

        expect(copy.isTraceSizeVisible).toEqual(false);
      });
    });

    it('sets trace, trace size and isTraceComplete', () => {
      mutations[types.RECEIVE_TRACE_SUCCESS](stateCopy, {
        append: true,
        html,
        size: 511846,
        complete: true,
      });
      expect(stateCopy.trace).toEqual(html);
      expect(stateCopy.traceSize).toEqual(511846);
      expect(stateCopy.isTraceComplete).toEqual(true);
    });
  });

  describe('STOP_POLLING_TRACE', () => {
    it('sets isTraceComplete to true', () => {
      mutations[types.STOP_POLLING_TRACE](stateCopy);
      expect(stateCopy.isTraceComplete).toEqual(true);
    });
  });

  describe('RECEIVE_TRACE_ERROR', () => {
    it('resets trace state and sets error to true', () => {
      mutations[types.RECEIVE_TRACE_ERROR](stateCopy);
      expect(stateCopy.isLoadingTrace).toEqual(false);
      expect(stateCopy.isTraceComplete).toEqual(true);
      expect(stateCopy.hasTraceError).toEqual(true);
    });
  });

  describe('REQUEST_JOB', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_JOB](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_JOB_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_JOB_SUCCESS](stateCopy, { id: 1312321 });
    });

    it('sets is loading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('sets hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('sets job data', () => {
      expect(stateCopy.job).toEqual({ id: 1312321 });
    });
  });

  describe('RECEIVE_JOB_ERROR', () => {
    it('resets job data', () => {
      mutations[types.RECEIVE_JOB_ERROR](stateCopy);

      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.hasError).toEqual(true);
      expect(stateCopy.job).toEqual({});
    });
  });

  describe('SCROLL_TO_TOP', () => {
    beforeEach(() => {
      mutations[types.SCROLL_TO_TOP](stateCopy);
    });

    it('sets isTraceScrolledToBottom to false', () => {
      expect(stateCopy.isTraceScrolledToBottom).toEqual(false);
    });

    it('sets hasBeenScrolled to true', () => {
      expect(stateCopy.hasBeenScrolled).toEqual(true);
    });
  });

  describe('SCROLL_TO_BOTTOM', () => {
    beforeEach(() => {
      mutations[types.SCROLL_TO_BOTTOM](stateCopy);
    });

    it('sets isTraceScrolledToBottom to true', () => {
      expect(stateCopy.isTraceScrolledToBottom).toEqual(true);
    });

    it('sets hasBeenScrolled to true', () => {
      expect(stateCopy.hasBeenScrolled).toEqual(true);
    });
  });

  describe('REQUEST_STAGES', () => {
    it('sets isLoadingStages to true', () => {
      mutations[types.REQUEST_STAGES](stateCopy);
      expect(stateCopy.isLoadingStages).toEqual(true);
    });
  });

  describe('RECEIVE_STAGES_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_STAGES_SUCCESS](stateCopy, [{ name: 'build' }]);
    });

    it('sets isLoadingStages to false', () => {
      expect(stateCopy.isLoadingStages).toEqual(false);
    });

    it('sets stages', () => {
      expect(stateCopy.stages).toEqual([{ name: 'build' }]);
    });
  });

  describe('RECEIVE_STAGES_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_STAGES_ERROR](stateCopy);
    });

    it('sets isLoadingStages to false', () => {
      expect(stateCopy.isLoadingStages).toEqual(false);
    });

    it('resets stages', () => {
      expect(stateCopy.stages).toEqual([]);
    });
  });

  describe('REQUEST_JOBS_FOR_STAGE', () => {
    it('sets isLoadingStages to true', () => {
      mutations[types.REQUEST_JOBS_FOR_STAGE](stateCopy);
      expect(stateCopy.isLoadingJobs).toEqual(true);
    });
  });

  describe('RECEIVE_JOBS_FOR_STAGE_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_JOBS_FOR_STAGE_SUCCESS](stateCopy, [{ name: 'karma' }]);
    });

    it('sets isLoadingJobs to false', () => {
      expect(stateCopy.isLoadingJobs).toEqual(false);
    });

    it('sets jobs', () => {
      expect(stateCopy.jobs).toEqual([{ name: 'karma' }]);
    });
  });

  describe('RECEIVE_JOBS_FOR_STAGE_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_JOBS_FOR_STAGE_ERROR](stateCopy);
    });

    it('sets isLoadingJobs to false', () => {
      expect(stateCopy.isLoadingJobs).toEqual(false);
    });

    it('resets jobs', () => {
      expect(stateCopy.jobs).toEqual([]);
    });
  });
});
