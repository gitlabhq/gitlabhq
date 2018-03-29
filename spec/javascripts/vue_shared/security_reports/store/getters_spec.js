import state from 'ee/vue_shared/security_reports/store/state';
import {
  groupedSastText,
  groupedSastContainerText,
  groupedDastText,
  groupedDependencyText,
  groupedSummaryText,
  allReportsHaveError,
  noBaseInAllReports,
  areReportsLoading,
  sastStatusIcon,
  sastContainerStatusIcon,
  dastStatusIcon,
  dependencyScanningStatusIcon,
  anyReportHasError,
} from 'ee/vue_shared/security_reports/store/getters';

describe('Security reports getters', () => {
  function removeBreakLine (data) {
    return data.replace(/\r?\n|\r/g, '').replace(/\s\s+/g, ' ');
  }

  describe('groupedSastText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        expect(groupedSastText(state())).toEqual('SAST detected no security vulnerabilities');
      });
    });

    describe('with only `all` issues', () => {
      it('returns no new issues text', () => {
        const newState = state();
        newState.sast.allIssues = [{}];

        expect(groupedSastText(newState)).toEqual('SAST detected no new security vulnerabilities');
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.sast.paths.head = 'foo';
        newState.sast.newIssues = [{}];

        expect(groupedSastText(newState)).toEqual(
          'SAST was unable to compare existing and new vulnerabilities. It detected 1 vulnerability',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.sast.paths.head = 'foo';
          newState.sast.paths.base = 'bar';
          newState.sast.newIssues = [{}];

          expect(groupedSastText(newState)).toEqual('SAST detected 1 new vulnerability');
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.sast.paths.head = 'foo';
          newState.sast.paths.base = 'bar';
          newState.sast.newIssues = [{}];
          newState.sast.resolvedIssues = [{}];

          expect(removeBreakLine(groupedSastText(newState))).toEqual(
            'SAST detected 1 new vulnerability and 1 fixed vulnerability',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.sast.paths.head = 'foo';
          newState.sast.paths.base = 'bar';
          newState.sast.resolvedIssues = [{}];

          expect(groupedSastText(newState)).toEqual('SAST detected 1 fixed vulnerability');
        });
      });
    });
  });

  describe('groupedSastContainerText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        expect(groupedSastContainerText(state())).toEqual(
          'Container scanning detected no security vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.sastContainer.paths.head = 'foo';
        newState.sastContainer.newIssues = [{}];

        expect(groupedSastContainerText(newState)).toEqual(
          'Container scanning was unable to compare existing and new vulnerabilities. It detected 1 vulnerability',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = 'foo';
          newState.sastContainer.paths.base = 'foo';
          newState.sastContainer.newIssues = [{}];

          expect(groupedSastContainerText(newState)).toEqual(
            'Container scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = 'foo';
          newState.sastContainer.paths.base = 'foo';
          newState.sastContainer.newIssues = [{}];
          newState.sastContainer.resolvedIssues = [{}];

          expect(removeBreakLine(groupedSastContainerText(newState))).toEqual(
            'Container scanning detected 1 new vulnerability and 1 fixed vulnerability',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.sastContainer.paths.head = 'foo';
          newState.sastContainer.paths.base = 'foo';
          newState.sastContainer.resolvedIssues = [{}];

          expect(groupedSastContainerText(newState)).toEqual(
            'Container scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('groupedDastText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        expect(groupedDastText(state())).toEqual('DAST detected no security vulnerabilities');
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.dast.paths.head = 'foo';
        newState.dast.newIssues = [{}];

        expect(groupedDastText(newState)).toEqual(
          'DAST was unable to compare existing and new vulnerabilities. It detected 1 vulnerability',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.dast.paths.head = 'foo';
          newState.dast.paths.base = 'foo';
          newState.dast.newIssues = [{}];

          expect(groupedDastText(newState)).toEqual('DAST detected 1 new vulnerability');
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.dast.paths.head = 'foo';
          newState.dast.paths.base = 'foo';
          newState.dast.newIssues = [{}];
          newState.dast.resolvedIssues = [{}];

          expect(removeBreakLine(groupedDastText(newState))).toEqual(
            'DAST detected 1 new vulnerability and 1 fixed vulnerability',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.dast.paths.head = 'foo';
          newState.dast.paths.base = 'foo';
          newState.dast.resolvedIssues = [{}];
          expect(groupedDastText(newState)).toEqual('DAST detected 1 fixed vulnerability');
        });
      });
    });
  });

  describe('groupedDependencyText', () => {
    describe('with no issues', () => {
      it('returns no issues text', () => {
        expect(groupedDependencyText(state())).toEqual(
          'Dependency scanning detected no security vulnerabilities',
        );
      });
    });

    describe('with new issues and without base', () => {
      it('returns unable to compare text', () => {
        const newState = state();
        newState.dependencyScanning.paths.head = 'foo';
        newState.dependencyScanning.newIssues = [{}];

        expect(groupedDependencyText(newState)).toEqual(
          'Dependency scanning was unable to compare existing and new vulnerabilities. It detected 1 vulnerability',
        );
      });
    });

    describe('with base and head', () => {
      describe('with only new issues', () => {
        it('returns new issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = 'foo';
          newState.dependencyScanning.paths.base = 'foo';
          newState.dependencyScanning.newIssues = [{}];
          expect(groupedDependencyText(newState)).toEqual(
            'Dependency scanning detected 1 new vulnerability',
          );
        });
      });

      describe('with new and resolved issues', () => {
        it('returns new and fixed issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = 'foo';
          newState.dependencyScanning.paths.base = 'foo';
          newState.dependencyScanning.newIssues = [{}];
          newState.dependencyScanning.resolvedIssues = [{}];

          expect(removeBreakLine(groupedDependencyText(newState))).toEqual(
            'Dependency scanning detected 1 new vulnerability and 1 fixed vulnerability',
          );
        });
      });

      describe('with only resolved issues', () => {
        it('returns fixed issues text', () => {
          const newState = state();
          newState.dependencyScanning.paths.head = 'foo';
          newState.dependencyScanning.paths.base = 'foo';

          newState.dependencyScanning.resolvedIssues = [{}];
          expect(groupedDependencyText(newState)).toEqual(
            'Dependency scanning detected 1 fixed vulnerability',
          );
        });
      });
    });
  });

  describe('groupedSummaryText', () => {
    it('returns failed text', () => {
      expect(
        groupedSummaryText(state(), {
          allReportsHaveError: true,
          noBaseInAllReports: false,
          areReportsLoading: false,
        }),
      ).toEqual('Security scanning failed loading any results');
    });

    it('returns no compare text', () => {
      expect(
        groupedSummaryText(state(), {
          allReportsHaveError: false,
          noBaseInAllReports: true,
          areReportsLoading: false,
        }),
      ).toEqual(
        'Security scanning was unable to compare existing and new vulnerabilities. It detected no vulnerabilities.',
      );
    });

    it('returns in progress text', () => {
      expect(
        groupedSummaryText(state(), {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: true,
        }),
      ).toContain('(in progress)');
    });

    it('returns added and fixed text', () => {
      const newState = state();
      newState.summaryCounts = {
        added: 2,
        fixed: 4,
      };

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
        }),
      ).toContain('Security scanning detected 2 new vulnerabilities and 4 fixed vulnerabilities');
    });

    it('returns added text', () => {
      const newState = state();
      newState.summaryCounts = {
        added: 2,
        fixed: 0,
      };

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
        }),
      ).toContain('Security scanning detected 2 new vulnerabilities');
    });

    it('returns fixed text', () => {
      const newState = Object.assign({}, state());
      newState.summaryCounts = {
        added: 0,
        fixed: 4,
      };

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: false,
        }),
      ).toContain('Security scanning detected 4 fixed vulnerabilities');
    });

    it('returns added and fixed while loading text', () => {
      const newState = Object.assign({}, state());
      newState.summaryCounts = {
        added: 2,
        fixed: 4,
      };

      expect(
        groupedSummaryText(newState, {
          allReportsHaveError: false,
          noBaseInAllReports: false,
          areReportsLoading: true,
        }),
      ).toContain(
        'Security scanning (in progress) detected 2 new vulnerabilities and 4 fixed vulnerabilities',
      );
    });
  });

  describe('sastStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = Object.assign({}, state());
      newState.sast.newIssues = [{}];
      expect(sastStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = Object.assign({}, state());
      newState.sast.hasError = true;
      expect(sastStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(sastStatusIcon(state())).toEqual('success');
    });
  });

  describe('dastStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = Object.assign({}, state());
      newState.dast.newIssues = [{}];
      expect(dastStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = Object.assign({}, state());
      newState.dast.hasError = true;
      expect(dastStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dastStatusIcon(state())).toEqual('success');
    });
  });

  describe('sastContainerStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = Object.assign({}, state());
      newState.sastContainer.newIssues = [{}];
      expect(sastContainerStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = Object.assign({}, state());
      newState.sastContainer.hasError = true;
      expect(sastContainerStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(sastContainerStatusIcon(state())).toEqual('success');
    });
  });

  describe('dependencyScanningStatusIcon', () => {
    it('returns warning with new issues', () => {
      const newState = Object.assign({}, state());
      newState.dependencyScanning.newIssues = [{}];
      expect(dependencyScanningStatusIcon(newState)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      const newState = Object.assign({}, state());
      newState.dependencyScanning.hasError = true;
      expect(dependencyScanningStatusIcon(newState)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dependencyScanningStatusIcon(state())).toEqual('success');
    });
  });

  describe('areReportsLoading', () => {
    it('returns true when any report is loading', () => {
      const newState = Object.assign({}, state());
      newState.sast.isLoading = true;
      expect(areReportsLoading(newState)).toEqual(true);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areReportsLoading(state())).toEqual(false);
    });
  });

  describe('allReportsHaveError', () => {
    it('returns true when all reports have error', () => {
      const newState = Object.assign({}, state());
      newState.sast.hasError = true;
      newState.dast.hasError = true;
      newState.sastContainer.hasError = true;
      newState.dependencyScanning.hasError = true;

      expect(allReportsHaveError(newState)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(allReportsHaveError(state())).toEqual(false);
    });
  });

  describe('anyReportHasError', () => {
    it('returns true when any of the reports has error', () => {
      const newState = Object.assign({}, state());
      newState.sast.hasError = true;

      expect(anyReportHasError(newState)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasError(state())).toEqual(false);
    });
  });

  describe('noBaseInAllReports', () => {
    it('returns true when none reports have base', () => {
      expect(noBaseInAllReports(state())).toEqual(true);
    });

    it('returns false when any of the reports has base', () => {
      const newState = Object.assign({}, state());
      newState.sast.paths.base = 'foo';
      expect(noBaseInAllReports(newState)).toEqual(false);
    });
  });
});
