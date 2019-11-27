import { mount, createLocalVue } from '@vue/test-utils';
import MrWidgetPipelineContainer from '~/vue_merge_request_widget/components/mr_widget_pipeline_container.vue';
import MrWidgetPipeline from '~/vue_merge_request_widget/components/mr_widget_pipeline.vue';
import ArtifactsApp from '~/vue_merge_request_widget/components/artifacts_list_app.vue';
import { mockStore } from '../mock_data';

const localVue = createLocalVue();

describe('MrWidgetPipelineContainer', () => {
  let wrapper;

  const factory = (props = {}) => {
    wrapper = mount(localVue.extend(MrWidgetPipelineContainer), {
      propsData: {
        mr: Object.assign({}, mockStore),
        ...props,
      },
      localVue,
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when pre merge', () => {
    beforeEach(() => {
      factory();
    });

    it('renders pipeline', () => {
      expect(wrapper.find(MrWidgetPipeline).exists()).toBe(true);
      expect(wrapper.find(MrWidgetPipeline).props()).toEqual(
        jasmine.objectContaining({
          pipeline: mockStore.pipeline,
          ciStatus: mockStore.ciStatus,
          hasCi: mockStore.hasCI,
          sourceBranch: mockStore.sourceBranch,
          sourceBranchLink: mockStore.sourceBranchLink,
        }),
      );
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.deployments.map(dep =>
        jasmine.objectContaining({
          deployment: dep,
          showMetrics: false,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-pre-deployment');

      expect(deployments.wrappers.map(x => x.props())).toEqual(expectedProps);
    });
  });

  describe('when post merge', () => {
    beforeEach(() => {
      factory({
        isPostMerge: true,
      });
    });

    it('renders pipeline', () => {
      expect(wrapper.find(MrWidgetPipeline).exists()).toBe(true);
      expect(wrapper.find(MrWidgetPipeline).props()).toEqual(
        jasmine.objectContaining({
          pipeline: mockStore.mergePipeline,
          ciStatus: mockStore.ciStatus,
          hasCi: mockStore.hasCI,
          sourceBranch: mockStore.targetBranch,
          sourceBranchLink: mockStore.targetBranch,
        }),
      );
    });

    it('renders deployments', () => {
      const expectedProps = mockStore.postMergeDeployments.map(dep =>
        jasmine.objectContaining({
          deployment: dep,
          showMetrics: true,
        }),
      );

      const deployments = wrapper.findAll('.mr-widget-extension .js-post-deployment');

      expect(deployments.wrappers.map(x => x.props())).toEqual(expectedProps);
    });
  });

  describe('with artifacts path', () => {
    it('renders the artifacts app', () => {
      expect(wrapper.find(ArtifactsApp).isVisible()).toBe(true);
    });
  });
});
