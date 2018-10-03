import * as getters from '~/jobs/store/getters';
import state from '~/jobs/store/state';

describe('Job Store Getters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('headerActions', () => {
    describe('with new issue path', () => {
      it('returns an array with action to create a new issue', () => {
        localState.job.new_issue_path = 'issues/new';

        expect(getters.headerActions(localState)).toEqual([
          {
            label: 'New issue',
            path: localState.job.new_issue_path,
            cssClass:
              'js-new-issue btn btn-success btn-inverted d-none d-md-block d-lg-block d-xl-block',
            type: 'link',
          },
        ]);
      });
    });

    describe('without new issue path', () => {
      it('returns an empty array', () => {
        expect(getters.headerActions(localState)).toEqual([]);
      });
    });
  });

  describe('headerTime', () => {
    describe('when the job has started key', () => {
      it('returns started key', () => {
        const started = '2018-08-31T16:20:49.023Z';
        localState.job.started = started;

        expect(getters.headerTime(localState)).toEqual(started);
      });
    });

    describe('when the job does not have started key', () => {
      it('returns created_at key', () => {
        const created = '2018-08-31T16:20:49.023Z';
        localState.job.created_at = created;
        expect(getters.headerTime(localState)).toEqual(created);
      });
    });
  });

  describe('shouldRenderCalloutMessage', () => {
    describe('with status and callout message', () => {
      it('returns true', () => {
        localState.job.callout_message = 'Callout message';
        localState.job.status = { icon: 'passed' };

        expect(getters.shouldRenderCalloutMessage(localState)).toEqual(true);
      });
    });

    describe('without status & with callout message', () => {
      it('returns false', () => {
        localState.job.callout_message = 'Callout message';
        expect(getters.shouldRenderCalloutMessage(localState)).toEqual(false);
      });
    });

    describe('with status & without callout message', () => {
      it('returns false', () => {
        localState.job.status = { icon: 'passed' };

        expect(getters.shouldRenderCalloutMessage(localState)).toEqual(false);
      });
    });
  });

  describe('jobHasStarted', () => {
    describe('when started equals false', () => {
      it('returns false', () => {
        localState.job.started = false;
        expect(getters.jobHasStarted(localState)).toEqual(false);
      });
    });

    describe('when started equals string', () => {
      it('returns true', () => {
        localState.job.started = '2018-08-31T16:20:49.023Z';
        expect(getters.jobHasStarted(localState)).toEqual(true);
      });
    });
  });

  describe('hasEnvironment', () => {
    describe('without `deployment_status`', () => {
      it('returns false', () => {
        expect(getters.hasEnvironment(localState)).toEqual(false);
      });
    });
    describe('with an empty object for `deployment_status`', () => {
      it('returns false', () => {
        localState.job.deployment_status = {};
        expect(getters.hasEnvironment(localState)).toEqual(false);
      });
    });
    describe('when `deployment_status` is defined and not empty', () => {
      it('returns true', () => {
        localState.job.deployment_status = {
          status: 'creating',
          environment: {
            last_deployment: {},
          },
        };

        expect(getters.hasEnvironment(localState)).toEqual(true);
      });
    });
  });
});
