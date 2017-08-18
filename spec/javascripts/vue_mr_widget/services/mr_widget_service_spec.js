import Vue from 'vue';
import VueResource from 'vue-resource';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

Vue.use(VueResource);

describe('MRWidgetService', () => {
  const mr = {
    mergePath: './',
    mergeCheckPath: './',
    cancelAutoMergePath: './',
    removeWIPPath: './',
    sourceBranchPath: './',
    ciEnvironmentsStatusPath: './',
    statusPath: './',
    mergeActionsContentPath: './',
    isServiceStore: true,
  };

  it('should have store and resources created in constructor', () => {
    const service = new MRWidgetService(mr);

    expect(service.mergeResource).toBeDefined();
    expect(service.mergeCheckResource).toBeDefined();
    expect(service.cancelAutoMergeResource).toBeDefined();
    expect(service.removeWIPResource).toBeDefined();
    expect(service.removeSourceBranchResource).toBeDefined();
    expect(service.deploymentsResource).toBeDefined();
    expect(service.pollResource).toBeDefined();
    expect(service.mergeActionsContentResource).toBeDefined();
  });

  it('should have methods defined', () => {
    const service = new MRWidgetService(mr);

    expect(service.merge()).toBeDefined();
    expect(service.cancelAutomaticMerge()).toBeDefined();
    expect(service.removeWIP()).toBeDefined();
    expect(service.removeSourceBranch()).toBeDefined();
    expect(service.fetchDeployments()).toBeDefined();
    expect(service.poll()).toBeDefined();
    expect(service.checkStatus()).toBeDefined();
    expect(service.fetchMergeActionsContent()).toBeDefined();
    expect(MRWidgetService.stopEnvironment()).toBeDefined();
  });
});
