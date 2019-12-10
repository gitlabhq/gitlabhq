import Vue from 'vue';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import mockData from './linked_pipelines_mock_data';

describe('Linked Pipelines Column', () => {
  const Component = Vue.extend(LinkedPipelinesColumn);
  const props = {
    columnTitle: 'Upstream',
    linkedPipelines: mockData.triggered,
    graphPosition: 'right',
  };
  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the pipeline orientation', () => {
    const titleElement = vm.$el.querySelector('.linked-pipelines-column-title');

    expect(titleElement.innerText).toContain(props.columnTitle);
  });

  it('has the correct number of linked pipeline child components', () => {
    expect(vm.$children.length).toBe(props.linkedPipelines.length);
  });

  it('renders the correct number of linked pipelines', () => {
    const linkedPipelineElements = vm.$el.querySelectorAll('.linked-pipeline');

    expect(linkedPipelineElements.length).toBe(props.linkedPipelines.length);
  });

  it('renders cross project triangle when column is upstream', () => {
    expect(vm.$el.querySelector('.cross-project-triangle')).toBeDefined();
  });
});
