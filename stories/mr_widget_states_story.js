import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, text } from '@storybook/addon-knobs';
import * as mrWidget from '../app/assets/javascripts/vue_merge_request_widget/dependencies';
import mockData from '../spec/javascripts/vue_mr_widget/mock_data';

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const author = {
  webUrl: 'http://foo.bar',
  avatarUrl: 'http://gravatar.com/foo',
  name: 'fatihacet',
};

const stories = storiesOf('MR Widget.States', module);

const defaultCombinations = [
  {
    title: 'default',
  },
];

const defaultComponent = {
  template: '<h2 class="error">Component not found</h2>',
};

function makeStories({
  title,
  component = defaultComponent,
  service = {},
  combinations = defaultCombinations,
}) {
  stories.add(title, () => ({
    data() {
      return {
        service,
        component,
      };
    },
    computed: {
      sections() {
        return combinations.map(section => ({
          ...section,
          props: section.props || {},
        }));
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <template v-for="section in sections">
            <h3>{{section.title}}</h3>
              <div class="mr-state-widget prepend-top-default">
                <div class="mr-widget-section">
                  <component
                    :is="component"
                    :mr="section.props"
                    :service="service" />
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    `,
  }));
}

makeStories({
  title: 'Archived',
  component: mrWidget.ArchivedState,
  combinations: [
    {
      title: 'default',
    },
  ],
});

makeStories({
  title: 'Auto merge failed',
  component: mrWidget.AutoMergeFailed,
  combinations: [
    {
      title: 'default',
    },
    {
      title: 'with merge error',
      props: {
        mergeError: 'Conflicts detected',
      },
    },
  ],
});

makeStories({
  title: 'Checking',
  component: mrWidget.CheckingState,
});

makeStories({
  title: 'Closed',
  component: mrWidget.ClosedState,
  combinations: [
    {
      title: 'default',
      props: {
        closedBy: author,
        closedAt: 'a while ago',
        updatedAt: '3 mins ago',
        targetBranch: 'master',
      },
    },
  ],
});

makeStories({
  title: 'Conflicts',
  component: mrWidget.ConflictsState,
  combinations: [
    {
      title: 'Cannot merge',
    },
    {
      title: 'Can merge',
      props: {
        canMerge: true,
        conflictResolutionPath: '/conflicts',
      },
    },
  ],
});

makeStories({
  title: 'Failed to merge',
  component: mrWidget.FailedToMerge,
});

makeStories({
  title: 'Locked',
  component: mrWidget.LockedState,
  combinations: [
    {
      title: 'default',
      props: {
        state: 'locked',
        targetBranchPath: '/branch-path',
        targetBranch: 'branch',
      },
    },
  ],
});

makeStories({
  title: 'Merge when pipeline succeeds',
  component: mrWidget.MergeWhenPipelineSucceedsState,
  service: {
    cancelAutomaticMerge() {},
    mergeResource: {
      save() {},
    },
  },
  combinations: [
    {
      shouldRemoveSourceBranch: false,
      canRemoveSourceBranch: true,
      canCancelAutomaticMerge: true,
      mergeUserId: 1,
      currentUserId: 1,
      setToMWPSBy: {},
      sha: '1EA2EZ34',
      targetBranchPath: '/foo/bar',
      targetBranch: 'foo',
    },
  ],
});

const mergedProps = {
  state: 'merged',
  isRemovingSourceBranch: false,
  canRemoveSourceBranch: true,
  sourceBranchRemoved: true,
  updatedAt: '',
  targetBranch: 'foo',
  mergedAt: 'some time ago',
  mergedBy: {
    webUrl: 'http://foo.bar',
    avatarUrl: 'http://gravatar.com/foo',
    name: 'fatihacet',
  },
};

makeStories({
  title: 'Merged',
  component: mrWidget.MergedState,
  combinations: [
    {
      title: 'can remove source branch',
      props: {
        ...mergedProps,
        canRevertInCurrentMR: true,
        canCherryPickInCurrentMR: true,
        canRemoveSourceBranch: true,
        sourceBranchRemoved: false,
      },
    },
    {
      title: 'can revert',
      props: {
        ...mergedProps,
        canRevertInCurrentMR: true,
        canCherryPickInCurrentMR: true,
      },
    },
    {
      title: 'can revert in fork',
      props: {
        ...mergedProps,
        revertInForkPath: 'revert',
        cherryPickInForkPath: 'revert',
      },
    },
    {
      title: 'can cherry-pick',
      props: {
        ...mergedProps,
        canCherryPickInCurrentMR: true,
      },
    },
    {
      title: 'can cherry-pick in fork',
      props: {
        ...mergedProps,
        cherryPickInForkPath: 'revert',
      },
    },
    {
      title: 'removing branch',
      props: {
        ...mergedProps,
        canRevertInCurrentMR: true,
        canCerryPickInCurrentMR: true,
        sourceBranchRemoved: false,
        isRemovingSourceBranch: true,
      },
    },
  ],
});

makeStories({
  title: 'Missing branch',
  component: mrWidget.MissingBranchState,
  combinations: [
    {
      title: 'source branch removed',
      props: {
        sourceBranchRemoved: true,
      },
    },
    {
      title: 'target branch removed',
    },
  ],
});

makeStories({
  title: 'Not allowed',
  component: mrWidget.NotAllowedState,
});

makeStories({
  title: 'Nothing to merge',
  component: mrWidget.NothingToMergeState,
});

makeStories({
  title: 'Pipeline blocked',
  component: mrWidget.PipelineBlockedState,
});

makeStories({
  title: 'Pipeline failed',
  component: mrWidget.PipelineFailedState,
});

makeStories({
  title: 'Ready to merge',
  component: mrWidget.ReadyToMergeState,
  combinations: [
    {
      title: 'default',
      props: {
        commitMessage: 'a commit message',
      },
    },
    {
      title: 'with description',
      props: {
        commitMessage: 'a commit message',
        onlyAllowMergeIfPipelineSucceeds: false,
        commitMessageLinkTitle: 'Commit message description',
      },
    },
    {
      title: 'has CI with unknown status',
      props: {
        commitMessage: 'a commit message',
        hasCI: true,
      },
    },
    {
      title: 'Show pipeline options dropdown',
      props: {
        commitMessage: 'a commit message',
        pipeline: {},
        isPipelineActive: true,
        onlyAllowMergeIfPipelineSucceeds: false,
      },
    },
    {
      title: 'Merge not allowed',
      props: {
        commitMessage: 'a commit message',
        onlyAllowMergeIfPipelineSucceeds: true,
        isPipelineFailed: true,
      },
    },
    {
      title: 'Show commit message editor (click Modify button)',
      props: {
        commitMessage: 'a commit message',
        showCommitMessageEditor: true,
      },
    },
  ],
});

makeStories({
  title: 'SHA Mismatch',
  component: mrWidget.SHAMismatchState,
});

makeStories({
  title: 'Squash before merge',
  component: mrWidget.SquashBeforeMerge,
  combinations: [
    { title: 'EE-only feature' },
  ],
});

makeStories({
  title: 'Unresolved Discussions',
  component: mrWidget.UnresolvedDiscussionsState,
  combinations: [
    {
      title: 'can create issue',
      props: {
        createIssueToResolveDiscussionsPath: '/conflicts',
      },
    },
    {
      title: 'cannot create issue',
    },
  ],
});

makeStories({
  title: 'Work in progress',
  component: mrWidget.WipState,
  service: {
    removeWIP() {},
  },
  combinations: [
    {
      title: 'default',
    },
    {
      title: 'Show Resolve button',
      props: {
        removeWIPPath: '/remove/wip',
      },
    },
  ],
});
