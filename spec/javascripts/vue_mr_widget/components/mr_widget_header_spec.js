import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import headerComponent from '~/vue_merge_request_widget/components/mr_widget_header.vue';

describe('MRWidgetHeader', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(headerComponent);
  });

  afterEach(() => {
    vm.$destroy();
    gon.relative_url_root = '';
  });

  const expectDownloadDropdownItems = () => {
    const downloadEmailPatchesEl = vm.$el.querySelector('.js-download-email-patches');
    const downloadPlainDiffEl = vm.$el.querySelector('.js-download-plain-diff');

    expect(downloadEmailPatchesEl.textContent.trim()).toEqual('Email patches');
    expect(downloadEmailPatchesEl.getAttribute('href')).toEqual('/mr/email-patches');
    expect(downloadPlainDiffEl.textContent.trim()).toEqual('Plain diff');
    expect(downloadPlainDiffEl.getAttribute('href')).toEqual('/mr/plainDiffPath');
  };

  describe('computed', () => {
    describe('shouldShowCommitsBehindText', () => {
      it('return true when there are divergedCommitsCount', () => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'master',
            statusPath: 'abc',
          },
        });

        expect(vm.shouldShowCommitsBehindText).toEqual(true);
      });

      it('returns false where there are no divergedComits count', () => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 0,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'master',
            statusPath: 'abc',
          },
        });

        expect(vm.shouldShowCommitsBehindText).toEqual(false);
      });
    });

    describe('commitsBehindText', () => {
      it('returns singular when there is one commit', () => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 1,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'master',
            targetBranchPath: '/foo/bar/master',
            statusPath: 'abc',
          },
        });

        expect(vm.commitsBehindText).toEqual(
          'The source branch is <a href="/foo/bar/master">1 commit behind</a> the target branch',
        );
      });

      it('returns plural when there is more than one commit', () => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 2,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'master',
            targetBranchPath: '/foo/bar/master',
            statusPath: 'abc',
          },
        });

        expect(vm.commitsBehindText).toEqual(
          'The source branch is <a href="/foo/bar/master">2 commits behind</a> the target branch',
        );
      });
    });
  });

  describe('template', () => {
    describe('common elements', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'master',
            isOpen: true,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('renders source branch link', () => {
        expect(vm.$el.querySelector('.js-source-branch').innerHTML).toEqual(
          '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
        );
      });

      it('renders clipboard button', () => {
        expect(vm.$el.querySelector('.btn-clipboard')).not.toEqual(null);
      });

      it('renders target branch', () => {
        expect(vm.$el.querySelector('.js-target-branch').textContent.trim()).toEqual('master');
      });
    });

    describe('with an open merge request', () => {
      const mrDefaultOptions = {
        iid: 1,
        divergedCommitsCount: 12,
        sourceBranch: 'mr-widget-refactor',
        sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
        sourceBranchRemoved: false,
        targetBranchPath: 'foo/bar/commits-path',
        targetBranchTreePath: 'foo/bar/tree/path',
        targetBranch: 'master',
        isOpen: true,
        canPushToSourceBranch: true,
        emailPatchesPath: '/mr/email-patches',
        plainDiffPath: '/mr/plainDiffPath',
        statusPath: 'abc',
        sourceProjectFullPath: 'root/gitlab-ce',
        targetProjectFullPath: 'gitlab-org/gitlab-ce',
      };

      afterEach(() => {
        vm.$destroy();
      });

      beforeEach(() => {
        vm = mountComponent(Component, {
          mr: Object.assign({}, mrDefaultOptions),
        });
      });

      it('renders checkout branch button with modal trigger', () => {
        const button = vm.$el.querySelector('.js-check-out-branch');

        expect(button.textContent.trim()).toEqual('Check out branch');
        expect(button.getAttribute('data-target')).toEqual('#modal_merge_info');
        expect(button.getAttribute('data-toggle')).toEqual('modal');
      });

      it('renders web ide button', () => {
        const button = vm.$el.querySelector('.js-web-ide');

        expect(button.textContent.trim()).toEqual('Open in Web IDE');
        expect(button.classList.contains('disabled')).toBe(false);
        expect(button.getAttribute('href')).toEqual(
          '/-/ide/project/root/gitlab-ce/merge_requests/1?target_project=gitlab-org%2Fgitlab-ce',
        );
      });

      it('renders web ide button in disabled state with no href', () => {
        const mr = Object.assign({}, mrDefaultOptions, { canPushToSourceBranch: false });
        vm = mountComponent(Component, { mr });

        const link = vm.$el.querySelector('.js-web-ide');

        expect(link.classList.contains('disabled')).toBe(true);
        expect(link.getAttribute('href')).toBeNull();
      });

      it('renders web ide button with blank query string if target & source project branch', done => {
        vm.mr.targetProjectFullPath = 'root/gitlab-ce';

        vm.$nextTick(() => {
          const button = vm.$el.querySelector('.js-web-ide');

          expect(button.textContent.trim()).toEqual('Open in Web IDE');
          expect(button.getAttribute('href')).toEqual(
            '/-/ide/project/root/gitlab-ce/merge_requests/1?target_project=',
          );

          done();
        });
      });

      it('renders web ide button with relative URL', done => {
        gon.relative_url_root = '/gitlab';
        vm.mr.iid = 2;

        vm.$nextTick(() => {
          const button = vm.$el.querySelector('.js-web-ide');

          expect(button.textContent.trim()).toEqual('Open in Web IDE');
          expect(button.getAttribute('href')).toEqual(
            '/gitlab/-/ide/project/root/gitlab-ce/merge_requests/2?target_project=gitlab-org%2Fgitlab-ce',
          );

          done();
        });
      });

      it('renders download dropdown with links', () => {
        expectDownloadDropdownItems();
      });
    });

    describe('with a closed merge request', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'master',
            isOpen: false,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('does not render checkout branch button with modal trigger', () => {
        const button = vm.$el.querySelector('.js-check-out-branch');

        expect(button).toEqual(null);
      });

      it('renders download dropdown with links', () => {
        expectDownloadDropdownItems();
      });
    });

    describe('without diverged commits', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 0,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'master',
            isOpen: true,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('does not render diverged commits info', () => {
        expect(vm.$el.querySelector('.diverged-commits-count')).toEqual(null);
      });
    });

    describe('with diverged commits', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'master',
            isOpen: true,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('renders diverged commits info', () => {
        expect(vm.$el.querySelector('.diverged-commits-count').textContent).toEqual(
          'The source branch is 12 commits behind the target branch',
        );

        expect(vm.$el.querySelector('.diverged-commits-count a').textContent).toEqual(
          '12 commits behind',
        );

        expect(vm.$el.querySelector('.diverged-commits-count a')).toHaveAttr(
          'href',
          vm.mr.targetBranchPath,
        );
      });
    });
  });
});
