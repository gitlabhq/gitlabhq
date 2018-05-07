import Vue from 'vue';
import LinkedPipelinesMiniList from 'ee/vue_shared/components/linked_pipelines_mini_list.vue';
import mockData from 'spec/pipelines/graph/linked_pipelines_mock_data';

const ListComponent = Vue.extend(LinkedPipelinesMiniList);

describe('Linked pipeline mini list', function() {
  describe('when passed an upstream pipeline as prop', () => {
    beforeEach(() => {
      this.component = new ListComponent({
        propsData: {
          triggeredBy: [mockData.triggered_by],
        },
      }).$mount();
    });

    it('should render one linked pipeline item', () => {
      expect(this.component.$el.querySelectorAll('.linked-pipeline-mini-item').length).toBe(1);
    });

    it('should render a linked pipeline with the correct href', () => {
      const linkElement = this.component.$el.querySelector('.linked-pipeline-mini-item');
      expect(linkElement.getAttribute('href')).toBe('/gitlab-org/gitlab-ce/pipelines/129');
    });

    it('should render one ci status icon', () => {
      expect(this.component.$el.querySelectorAll('.linked-pipeline-mini-item svg').length).toBe(1);
    });

    it('should render the correct ci status icon', () => {
      const iconElement = this.component.$el.querySelector('.linked-pipeline-mini-item');
      expect(iconElement.classList.contains('ci-status-icon-running')).toBe(true);
      expect(iconElement.innerHTML).toContain('<svg');
    });

    it('should render an arrow icon', () => {
      const iconElement = this.component.$el.querySelector('.arrow-icon');
      expect(iconElement).not.toBeNull();
      expect(iconElement.innerHTML).toContain('<svg');
    });

    it('should have an activated tooltip', () => {
      const itemElement = this.component.$el.querySelector('.linked-pipeline-mini-item');
      expect(itemElement.getAttribute('data-original-title')).toBe('GitLabCE - running');
    });

    it('should correctly set is-upstream', () => {
      expect(this.component.$el.classList.contains('is-upstream')).toBe(true);
    });

    it('should correctly compute shouldRenderCounter', () => {
      expect(this.component.shouldRenderCounter).toBe(false);
    });

    it('should not render the pipeline counter', () => {
      expect(this.component.$el.querySelector('.linked-pipelines-counter')).toBeNull();
    });
  });

  describe('when passed downstream pipelines as props', () => {
    beforeEach(() => {
      this.component = new ListComponent({
        propsData: {
          triggered: mockData.triggered,
          pipelinePath: 'my/pipeline/path',
        },
      }).$mount();
    });

    it('should render one linked pipeline item', () => {
      expect(
        this.component.$el.querySelectorAll(
          '.linked-pipeline-mini-item:not(.linked-pipelines-counter)',
        ).length,
      ).toBe(3);
    });

    it('should render three ci status icons', () => {
      expect(this.component.$el.querySelectorAll('.linked-pipeline-mini-item svg').length).toBe(3);
    });

    it('should render the correct ci status icon', () => {
      const iconElement = this.component.$el.querySelector('.linked-pipeline-mini-item');
      expect(iconElement.classList.contains('ci-status-icon-running')).toBe(true);
      expect(iconElement.innerHTML).toContain('<svg');
    });

    it('should render an arrow icon', () => {
      const iconElement = this.component.$el.querySelector('.arrow-icon');
      expect(iconElement).not.toBeNull();
      expect(iconElement.innerHTML).toContain('<svg');
    });

    it('should have prepped tooltips', () => {
      const itemElement = this.component.$el.querySelectorAll('.linked-pipeline-mini-item')[2];
      expect(itemElement.getAttribute('data-original-title')).toBe('GitLabCE - running');
    });

    it('should correctly set is-downstream', () => {
      expect(this.component.$el.classList.contains('is-downstream')).toBe(true);
    });

    it('should correctly compute shouldRenderCounter', () => {
      expect(this.component.shouldRenderCounter).toBe(true);
    });

    it('should correctly trim linkedPipelines', () => {
      expect(this.component.triggered.length).toBe(6);
      expect(this.component.linkedPipelinesTrimmed.length).toBe(3);
    });

    it('should render the pipeline counter', () => {
      expect(this.component.$el.querySelector('.linked-pipelines-counter')).not.toBeNull();
    });

    it('should set the correct pipeline path', () => {
      expect(
        this.component.$el.querySelector('.linked-pipelines-counter').getAttribute('href'),
      ).toBe('my/pipeline/path');
    });

    it('should render the correct counterTooltipText', () => {
      expect(
        this.component.$el
          .querySelector('.linked-pipelines-counter')
          .getAttribute('data-original-title'),
      ).toBe(this.component.counterTooltipText);
    });
  });
});
