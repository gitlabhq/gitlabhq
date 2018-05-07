import Vue from 'vue';
import LinkedPipelineComponent from 'ee/pipelines/components/graph/linked_pipeline.vue';
import mockData from './linked_pipelines_mock_data';

const LinkedPipeline = Vue.extend(LinkedPipelineComponent);
const mockPipeline = mockData.triggered[0];

describe('Linked pipeline', function() {
  beforeEach(() => {
    this.propsData = {
      pipelineId: mockPipeline.id,
      pipelinePath: mockPipeline.path,
      pipelineStatus: mockPipeline.details.status,
      projectName: mockPipeline.project.name,
    };

    this.linkedPipeline = new LinkedPipeline({
      propsData: this.propsData,
    }).$mount();
  });

  it('should return a defined Vue component', () => {
    expect(this.linkedPipeline).toBeDefined();
  });

  it('should render a list item as the containing element', () => {
    expect(this.linkedPipeline.$el.tagName).toBe('LI');
  });

  it('should render a link', () => {
    const linkElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-content');
    expect(linkElement).not.toBeNull();
  });

  it('should link to the correct path', () => {
    const linkElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-content');
    expect(linkElement.getAttribute('href')).toBe(this.propsData.pipelinePath);
  });

  it('should render the project name', () => {
    const projectNameElement = this.linkedPipeline.$el.querySelector(
      '.linked-pipeline-project-name',
    );
    expect(projectNameElement.innerText).toContain(this.propsData.projectName);
  });

  it('should render an svg within the status container', () => {
    const pipelineStatusElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-status');
    expect(pipelineStatusElement.querySelector('svg')).not.toBeNull();
  });

  it('should render the pipeline status icon svg', () => {
    const pipelineStatusElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-status');
    expect(pipelineStatusElement.querySelector('.ci-status-icon-running')).not.toBeNull();
    expect(pipelineStatusElement.innerHTML).toContain('<svg');
  });

  it('should render the correct pipeline status icon style selector', () => {
    const pipelineStatusElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-status');
    expect(pipelineStatusElement.firstChild.classList.contains('ci-status-icon-running')).toBe(
      true,
    );
  });

  it('should have a ci-status child component', () => {
    const ciStatusComponent = this.linkedPipeline.$children[0];
    expect(ciStatusComponent).toBeDefined();
    expect(ciStatusComponent.$el.classList.contains('ci-status-icon')).toBe(true);
  });

  it('should render the pipeline id', () => {
    const pipelineIdElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-id');
    expect(pipelineIdElement.innerText).toContain(`#${this.propsData.pipelineId}`);
  });

  it('should correctly compute the tooltip text', () => {
    expect(this.linkedPipeline.tooltipText).toContain(mockPipeline.project.name);
    expect(this.linkedPipeline.tooltipText).toContain(mockPipeline.details.status.label);
  });

  it('should render the tooltip text as the title attribute', () => {
    const tooltipRef = this.linkedPipeline.$el.querySelector('.linked-pipeline-content');
    const titleAttr = tooltipRef.getAttribute('data-original-title');

    expect(titleAttr).toContain(mockPipeline.project.name);
    expect(titleAttr).toContain(mockPipeline.details.status.label);
  });
});
