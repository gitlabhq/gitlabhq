import Vue from 'vue';
import headerComponent from '~/vue_merge_request_widget/components/mr_widget_header.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetHeader', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(headerComponent);
  });

  afterEach(() => {
    vm.$destroy();
  });

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

    describe('commitsText', () => {
      it('returns singular when there is one commit', () => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 1,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'master',
            statusPath: 'abc',
          },
        });

        expect(vm.commitsText).toEqual('1 commit behind');
      });

      it('returns plural when there is more than one commit', () => {
        vm = mountComponent(Component, {
          mr: {
            divergedCommitsCount: 2,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'master',
            statusPath: 'abc',
          },
        });

        expect(vm.commitsText).toEqual('2 commits behind');
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
      afterEach(() => {
        vm.$destroy();
      });

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

      it('renders checkout branch button with modal trigger', () => {
        const button = vm.$el.querySelector('.js-check-out-branch');

        expect(button.textContent.trim()).toEqual('Check out branch');
        expect(button.getAttribute('data-target')).toEqual('#modal_merge_info');
        expect(button.getAttribute('data-toggle')).toEqual('modal');
      });

      it('renders web ide button', () => {
        const button = vm.$el.querySelector('.js-web-ide');

        expect(button.textContent.trim()).toEqual('Web IDE');
        expect(button.getAttribute('href')).toEqual('undefined/-/ide/projectabc');
      });

      it('renders download dropdown with links', () => {
        expect(vm.$el.querySelector('.js-download-email-patches').textContent.trim()).toEqual(
          'Email patches',
        );

        expect(vm.$el.querySelector('.js-download-email-patches').getAttribute('href')).toEqual(
          '/mr/email-patches',
        );

        expect(vm.$el.querySelector('.js-download-plain-diff').textContent.trim()).toEqual(
          'Plain diff',
        );

        expect(vm.$el.querySelector('.js-download-plain-diff').getAttribute('href')).toEqual(
          '/mr/plainDiffPath',
        );
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

      it('does not render download dropdown with links', () => {
        expect(vm.$el.querySelector('.js-download-email-patches')).toEqual(null);

        expect(vm.$el.querySelector('.js-download-plain-diff')).toEqual(null);
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
        expect(vm.$el.querySelector('.diverged-commits-count').textContent.trim()).toEqual(
          '(12 commits behind)',
        );
      });
    });
  });
});
