import { storiesOf } from '@storybook/vue';
import { addonKnobs, boolean, select, text } from '@storybook/addon-knobs';
import camelize from 'camelize';
import Vue from 'vue';
import mrWidgetOptions from '../app/assets/javascripts/vue_merge_request_widget/mr_widget_options';
import {
  WidgetHeader,
  WidgetMergeHelp,
  WidgetPipeline,
  WidgetDeployment,
  WidgetRelatedLinks,
  MergedState,
  ClosedState,
  LockedState,
  WipState,
  ArchivedState,
  ConflictsState,
  NothingToMergeState,
  MissingBranchState,
  NotAllowedState,
  ReadyToMergeState,
  SHAMismatchState,
  UnresolvedDiscussionsState,
  PipelineBlockedState,
  PipelineFailedState,
  FailedToMerge,
  MergeWhenPipelineSucceedsState,
  AutoMergeFailed,
  CheckingState,
  MRWidgetStore,
  MRWidgetService,
  eventHub,
  stateMaps,
  SquashBeforeMerge,
  notify,
} from '../app/assets/javascripts/vue_merge_request_widget/dependencies';
import mockData from '../spec/javascripts/vue_mr_widget/mock_data';
import { prometheusMockData } from '../spec/javascripts/monitoring/prometheus_mock_data';
// gl global stuff that isn't imported
import '../app/assets/javascripts/lib/utils/datetime_utility';
import '../app/assets/javascripts/lib/utils/common_utils';

const mr = camelize(mockData);
mr.isOpen = true;
// copied from mr_widget_deployment_spec
mr.deployments = [
  {
    id: 15,
    name: 'review/diplo',
    url: '/root/acets-review-apps/environments/15',
    stop_url: '/root/acets-review-apps/environments/15/stop',
    metrics_url: '/root/acets-review-apps/environments/15/deployments/1/metrics',
    external_url: 'http://diplo.',
    external_url_formatted: 'diplo.',
    deployed_at: '2017-03-22T22:44:42.258Z',
    deployed_at_formatted: 'Mar 22, 2017 10:44pm',
  },
];
mr.relatedLinks = {
  closing: '<a href="#">#23</a> and <a>#42</a>',
  mentioned: '<a href="#">#7</a>',
};
mr.commitMessage = 'A commit';
mr.mergedAt = 'some time ago';
mr.mergedBy = {
  webUrl: 'http://foo.bar',
  avatarUrl: 'http://gravatar.com/foo',
  name: 'fatihacet',
};
mr.closedAt = mr.mergedAt;
mr.closedBy = mr.mergedBy;
mr.setToMWPSAt = mr.mergedAt;
mr.setToMWPSBy = mr.mergedBy;
mr.removeWIPPath = '/some/path';

window.gl.mrWidgetData = mr;
window.gon = window.gon || {};
window.gon.current_user_id = 1;

const stories = storiesOf('MR Widget', module);

const template = `
  <div class="mr-state-widget">
    <mr-widget-header
      :mr="mr" />
    ${// <mr-widget-pipeline :mr="mr" />
    ''}
    <mr-widget-deployment
      :mr="mr"
      :service="service" />
    <component
      :is="componentName"
      :mr="mr"
      :service="service" />
    <mr-widget-related-links
      :related-links="mr.relatedLinks" />
    <mr-widget-merge-help />
  </div>
`;

const makeWidget = props => ({
  components: {
    // TODO: copypaste from mr_widget_options
    'mr-widget-header': WidgetHeader,
    'mr-widget-merge-help': WidgetMergeHelp,
    'mr-widget-pipeline': WidgetPipeline,
    'mr-widget-deployment': WidgetDeployment,
    'mr-widget-related-links': WidgetRelatedLinks,
    'mr-widget-merged': MergedState,
    'mr-widget-closed': ClosedState,
    'mr-widget-locked': LockedState,
    'mr-widget-failed-to-merge': FailedToMerge,
    'mr-widget-wip': WipState,
    'mr-widget-archived': ArchivedState,
    'mr-widget-conflicts': ConflictsState,
    'mr-widget-nothing-to-merge': NothingToMergeState,
    'mr-widget-not-allowed': NotAllowedState,
    'mr-widget-missing-branch': MissingBranchState,
    'mr-widget-ready-to-merge': ReadyToMergeState,
    'mr-widget-sha-mismatch': SHAMismatchState,
    'mr-widget-squash-before-merge': SquashBeforeMerge,
    'mr-widget-checking': CheckingState,
    'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
    'mr-widget-pipeline-blocked': PipelineBlockedState,
    'mr-widget-pipeline-failed': PipelineFailedState,
    'mr-widget-merge-when-pipeline-succeeds': MergeWhenPipelineSucceedsState,
    'mr-widget-auto-merge-failed': AutoMergeFailed,
  },
  template,
  data: () => ({
    service: {},
    mr: {
      ...props,
      createIssueToResolveDiscussionsPath: text('Create issue', '/create/issue'),
      isPipelineActive: boolean('Pipeline active', false),
      shouldRemoveSourceBranch: boolean('shouldRemoveSourceBranch', true),
      canRemoveSourceBranch: boolean('canRemoveSourceBranch', true),
      mergeUserId: text('merge user ID', '1'),
      currentUserId: text('current user ID', '1'),
    },
  }),
  computed: {
    componentName() {
      return stateMaps.stateToComponentMap[this.mr.state];
    },
  },
});

const createComponent = () => {
  delete mrWidgetOptions.el; // Prevent component mounting
  gl.mrWidgetData = mockData;
  const Component = Vue.extend(mrWidgetOptions);
  return new Component();
};

function makeStory(options) {
  const props = {
    defaultState: 'checking',
    ...mr,
    ...options,
  };
  return addonKnobs()(() => makeWidget(props));
}

Object.keys(stateMaps.stateToComponentMap).forEach((state) => {
  stories.add(state, makeStory({
    state,
  }));
});
