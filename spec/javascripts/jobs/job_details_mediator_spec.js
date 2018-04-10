import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import JobMediator from '~/jobs/job_details_mediator';
import job from './mock_data';

describe('JobMediator', () => {
  let mediator;
  let mock;

  beforeEach(() => {
    mediator = new JobMediator({ endpoint: 'jobs/40291672.json' });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('should set defaults', () => {
    expect(mediator.store).toBeDefined();
    expect(mediator.service).toBeDefined();
    expect(mediator.options).toEqual({ endpoint: 'jobs/40291672.json' });
    expect(mediator.state.isLoading).toEqual(false);
  });

  describe('request and store data', () => {
    beforeEach(() => {
      mock.onGet().reply(200, job, {});
    });

    it('should store received data', (done) => {
      mediator.fetchJob();
      setTimeout(() => {
        expect(mediator.store.state.job).toEqual(job);
        done();
      }, 0);
    });
  });
});
