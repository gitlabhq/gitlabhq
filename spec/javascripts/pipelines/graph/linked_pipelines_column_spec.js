import Vue from 'vue';
import LinkedPipelinesColumn from '~/pipelines/components/graph/linked_pipelines_column.vue';

const LinkedPipelinesColumnComponent = Vue.extend(LinkedPipelinesColumn);

describe('Linked Pipelines Column', () => {
  beforeEach(() => {
    this.propsData = {
      linkedPipelinesOrientation: 'Upstream',
      linkedPipelines: [{}],
    };
    this.linkedPipelinesColumn = new LinkedPipelinesColumnComponent({
      propsData: this.propsData,
    });
  });

  it('instantiates a defined Vue component', () => {
    expect(this.linkedPipelinesColumn).toBeDefined();
  });

  it('renders the pipeline orientation', () => {
    const titleElement = this.linkedPipelinesColumn.$el.querySelector('.linked-pipelines-column-title');
    expect(titleElement).toContain(this.propsData.linkedPipelinesOrientation);
  });

  it('has the correct number of linked pipeline child components', () => {

  });

  it('renders the correct number of linked pipelines', () => {
    const linkedPipelineElements = this.linkedPipelinesColumn.$el.querySelectorAll('.linked-pipeline');
    expect(linkedPipelineElements.length).toBe(this.propsData.linkedPipelines.length);
  });
});

