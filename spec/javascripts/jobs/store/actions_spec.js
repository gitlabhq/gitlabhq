import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import {
  setJobEndpoint,
  setTraceEndpoint,
  setStagesEndpoint,
  setJobsEndpoint,
  clearEtagPoll,
  stopPolling,
  requestJob,
  fetchJob,
  receiveJobSuccess,
  receiveJobError,
  scrollTop,
  scrollBottom,
  requestTrace,
  fetchTrace,
  stopPollingTrace,
  receiveTraceSuccess,
  receiveTraceError,
  fetchFavicon,
  requestStatusFavicon,
  receiveStatusFaviconSuccess,
  requestStatusFaviconError,
  requestStages,
  fetchStages,
  receiveStagesSuccess,
  receiveStagesError,
  requestJobsForStage,
  setSelectedStage,
  fetchJobsForStage,
  receiveJobsForStageSuccess,
  receiveJobsForStageError,
} from '~/jobs/store/actions';
import state from '~/jobs/store/state';
import * as types from '~/jobs/store/mutation_types';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

describe('Job State actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setJobEndpoint', () => {
    it('should commit SET_JOB_ENDPOINT mutation', done => {
      testAction(
        setJobEndpoint,
        'job/872324.json',
        mockedState,
        [{ type: types.SET_JOB_ENDPOINT, payload: 'job/872324.json' }],
        [],
        done,
      );
    });
  });

  describe('setTraceEndpoint', () => {
    it('should commit SET_TRACE_ENDPOINT mutation', done => {
      testAction(
        setTraceEndpoint,
        'job/872324/trace.json',
        mockedState,
        [{ type: types.SET_TRACE_ENDPOINT, payload: 'job/872324/trace.json' }],
        [],
        done,
      );
    });
  });

  describe('setStagesEndpoint', () => {
    it('should commit SET_STAGES_ENDPOINT mutation', done => {
      testAction(
        setStagesEndpoint,
        'job/872324/stages.json',
        mockedState,
        [{ type: types.SET_STAGES_ENDPOINT, payload: 'job/872324/stages.json' }],
        [],
        done,
      );
    });
  });

  describe('setJobsEndpoint', () => {
    it('should commit SET_JOBS_ENDPOINT mutation', done => {
      testAction(
        setJobsEndpoint,
        'job/872324/stages/build.json',
        mockedState,
        [{ type: types.SET_JOBS_ENDPOINT, payload: 'job/872324/stages/build.json' }],
        [],
        done,
      );
    });
  });

  describe('requestJob', () => {
    it('should commit REQUEST_JOB mutation', done => {
      testAction(requestJob, null, mockedState, [{ type: types.REQUEST_JOB }], [], done);
    });
  });

  describe('fetchJob', () => {
    let mock;

    beforeEach(() => {
      mockedState.jobEndpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestJob and receiveJobSuccess ', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, { id: 121212, name: 'karma' });

        testAction(
          fetchJob,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestJob',
            },
            {
              payload: { id: 121212, name: 'karma' },
              type: 'receiveJobSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches requestJob and receiveJobError ', done => {
        testAction(
          fetchJob,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestJob',
            },
            {
              type: 'receiveJobError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveJobSuccess', () => {
    it('should commit RECEIVE_JOB_SUCCESS mutation', done => {
      testAction(
        receiveJobSuccess,
        { id: 121232132 },
        mockedState,
        [{ type: types.RECEIVE_JOB_SUCCESS, payload: { id: 121232132 } }],
        [],
        done,
      );
    });
  });

  describe('receiveJobError', () => {
    it('should commit RECEIVE_JOB_ERROR mutation', done => {
      testAction(receiveJobError, null, mockedState, [{ type: types.RECEIVE_JOB_ERROR }], [], done);
    });
  });

  describe('scrollTop', () => {
    it('should commit SCROLL_TO_TOP mutation', done => {
      testAction(scrollTop, null, mockedState, [{ type: types.SCROLL_TO_TOP }], [], done);
    });
  });

  describe('scrollBottom', () => {
    it('should commit SCROLL_TO_BOTTOM mutation', done => {
      testAction(scrollBottom, null, mockedState, [{ type: types.SCROLL_TO_BOTTOM }], [], done);
    });
  });

  describe('requestTrace', () => {
    it('should commit REQUEST_TRACE mutation', done => {
      testAction(requestTrace, null, mockedState, [{ type: types.REQUEST_TRACE }], [], done);
    });
  });

  describe('fetchTrace', () => {
    let mock;

    beforeEach(() => {
      mockedState.traceEndpoint = `${TEST_HOST}/endpoint`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestTrace, fetchFavicon, receiveTraceSuccess and stopPollingTrace when job is complete', done => {
        mock.onGet(`${TEST_HOST}/endpoint/trace.json`).replyOnce(200, {
          html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :',
          complete: true,
        });

        testAction(
          fetchTrace,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestTrace',
            },
            {
              type: 'fetchFavicon',
            },
            {
              payload: {
                html: 'I, [2018-08-17T22:57:45.707325 #1841]  INFO -- :', complete: true,
              },
              type: 'receiveTraceSuccess',
            },
            {
              type: 'stopPollingTrace',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint/trace.json`).reply(500);
      });

      it('dispatches requestTrace and receiveTraceError ', done => {
        testAction(
          fetchTrace,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestTrace',
            },
            {
              type: 'receiveTraceError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('stopPollingTrace', () => {
    it('should commit STOP_POLLING_TRACE mutation ', done => {
      testAction(
        stopPollingTrace,
        null,
        mockedState,
        [{ type: types.STOP_POLLING_TRACE }],
        [],
        done,
      );
    });
  });

  describe('receiveTraceSuccess', () => {
    it('should commit RECEIVE_TRACE_SUCCESS mutation ', done => {
      testAction(
        receiveTraceSuccess,
        'hello world',
        mockedState,
        [{ type: types.RECEIVE_TRACE_SUCCESS, payload: 'hello world' }],
        [],
        done,
      );
    });
  });

  describe('receiveTraceError', () => {
    it('should commit RECEIVE_TRACE_ERROR mutation ', done => {
      testAction(
        receiveTraceError,
        null,
        mockedState,
        [{ type: types.RECEIVE_TRACE_ERROR }],
        [],
        done,
      );
    });
  });

  describe('fetchFavicon', () => {
    let mock;

    beforeEach(() => {
      mockedState.pagePath = `${TEST_HOST}/endpoint`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestStatusFavicon and receiveStatusFaviconSuccess ', done => {
        mock.onGet(`${TEST_HOST}/endpoint/status.json`).replyOnce(200);

        testAction(
          fetchFavicon,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestStatusFavicon',
            },
            {
              type: 'receiveStatusFaviconSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint/status.json`).replyOnce(500);
      });

      it('dispatches requestStatusFavicon and requestStatusFaviconError ', done => {
        testAction(
          fetchFavicon,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestStatusFavicon',
            },
            {
              type: 'requestStatusFaviconError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestStatusFavicon', () => {
    it('should commit REQUEST_STATUS_FAVICON mutation ', done => {
      testAction(
        requestStatusFavicon,
        null,
        mockedState,
        [{ type: types.REQUEST_STATUS_FAVICON }],
        [],
        done,
      );
    });
  });

  describe('receiveStatusFaviconSuccess', () => {
    it('should commit RECEIVE_STATUS_FAVICON_SUCCESS mutation ', done => {
      testAction(
        receiveStatusFaviconSuccess,
        null,
        mockedState,
        [{ type: types.RECEIVE_STATUS_FAVICON_SUCCESS }],
        [],
        done,
      );
    });
  });

  describe('requestStatusFaviconError', () => {
    it('should commit RECEIVE_STATUS_FAVICON_ERROR mutation ', done => {
      testAction(
        requestStatusFaviconError,
        null,
        mockedState,
        [{ type: types.RECEIVE_STATUS_FAVICON_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestStages', () => {
    it('should commit REQUEST_STAGES mutation ', done => {
      testAction(requestStages, null, mockedState, [{ type: types.REQUEST_STAGES }], [], done);
    });
  });

  describe('fetchStages', () => {
    let mock;

    beforeEach(() => {
      mockedState.stagesEndpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestStages and receiveStagesSuccess ', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, [{ id: 121212, name: 'build' }]);

        testAction(
          fetchStages,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestStages',
            },
            {
              payload: [{ id: 121212, name: 'build' }],
              type: 'receiveStagesSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches requestStages and receiveStagesError ', done => {
        testAction(
          fetchStages,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestStages',
            },
            {
              type: 'receiveStagesError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveStagesSuccess', () => {
    it('should commit RECEIVE_STAGES_SUCCESS mutation ', done => {
      testAction(
        receiveStagesSuccess,
        {},
        mockedState,
        [{ type: types.RECEIVE_STAGES_SUCCESS, payload: {} }],
        [],
        done,
      );
    });
  });

  describe('receiveStagesError', () => {
    it('should commit RECEIVE_STAGES_ERROR mutation ', done => {
      testAction(
        receiveStagesError,
        null,
        mockedState,
        [{ type: types.RECEIVE_STAGES_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestJobsForStage', () => {
    it('should commit REQUEST_JOBS_FOR_STAGE mutation ', done => {
      testAction(
        requestJobsForStage,
        null,
        mockedState,
        [{ type: types.REQUEST_JOBS_FOR_STAGE }],
        [],
        done,
      );
    });
  });

  describe('setSelectedStage', () => {
    it('should commit SET_SELECTED_STAGE mutation ', done => {
      testAction(
        setSelectedStage,
        { name: 'build' },
        mockedState,
        [{ type: types.SET_SELECTED_STAGE, payload: { name: 'build' } }],
        [],
        done,
      );
    });
  });

  describe('fetchJobsForStage', () => {
    let mock;

    beforeEach(() => {
      mockedState.stageJobsEndpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches setSelectedStage, requestJobsForStage and receiveJobsForStageSuccess ', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, [{ id: 121212, name: 'build' }]);

        testAction(
          fetchJobsForStage,
          null,
          mockedState,
          [],
          [
            {
              type: 'setSelectedStage',
              payload: null,
            },
            {
              type: 'requestJobsForStage',
            },
            {
              payload: [{ id: 121212, name: 'build' }],
              type: 'receiveJobsForStageSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches setSelectedStage, requestJobsForStage and receiveJobsForStageError', done => {
        testAction(
          fetchJobsForStage,
          null,
          mockedState,
          [],
          [
            {
              payload: null,
              type: 'setSelectedStage',
            },
            {
              type: 'requestJobsForStage',
            },
            {
              type: 'receiveJobsForStageError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveJobsForStageSuccess', () => {
    it('should commit RECEIVE_JOBS_FOR_STAGE_SUCCESS mutation ', done => {
      testAction(
        receiveJobsForStageSuccess,
        [{ id: 121212, name: 'karma' }],
        mockedState,
        [{ type: types.RECEIVE_JOBS_FOR_STAGE_SUCCESS, payload: [{ id: 121212, name: 'karma' }] }],
        [],
        done,
      );
    });
  });

  describe('receiveJobsForStageError', () => {
    it('should commit RECEIVE_JOBS_FOR_STAGE_ERROR mutation ', done => {
      testAction(
        receiveJobsForStageError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOBS_FOR_STAGE_ERROR }],
        [],
        done,
      );
    });
  });
});
