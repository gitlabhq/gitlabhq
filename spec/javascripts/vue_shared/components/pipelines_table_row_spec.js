import Vue from 'vue';
import tableRowComp from '~/vue_shared/components/pipelines_table_row';
import pipeline from '../../commit/pipelines/mock_data';

describe('Pipelines Table Row', () => {
  let component;

  beforeEach(() => {
    const PipelinesTableRowComponent = Vue.extend(tableRowComp);

    component = new PipelinesTableRowComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        pipeline,
        service: {},
      },
    }).$mount();
  });

  it('should render a table row', () => {
    expect(component.$el).toEqual('TR');
  });

  describe('status column', () => {
    it('should render a pipeline link', () => {
      expect(
        component.$el.querySelector('td.commit-link a').getAttribute('href'),
      ).toEqual(pipeline.path);
    });

    it('should render status text', () => {
      expect(
        component.$el.querySelector('td.commit-link a').textContent,
      ).toContain(pipeline.details.status.text);
    });
  });

  describe('information column', () => {
    it('should render a pipeline link', () => {
      expect(
        component.$el.querySelector('td:nth-child(2) a').getAttribute('href'),
      ).toEqual(pipeline.path);
    });

    it('should render pipeline ID', () => {
      expect(
        component.$el.querySelector('td:nth-child(2) a > span').textContent,
      ).toEqual(`#${pipeline.id}`);
    });

    describe('when a user is provided', () => {
      it('should render user information', () => {
        expect(
          component.$el.querySelector('td:nth-child(2) a:nth-child(3)').getAttribute('href'),
        ).toEqual(pipeline.user.web_url);

        expect(
          component.$el.querySelector('td:nth-child(2) img').getAttribute('title'),
        ).toEqual(pipeline.user.name);
      });
    });

    it('should render commit author', () => {
      const commitTitleElement = component.$el.querySelector('.branch-commit .commit-title');
      const commitAuthorElement = commitTitleElement.querySelector('a.avatar-image-container');
      expect(commitAuthorElement.getAttribute('href')).toEqual(pipeline.commit.author.web_url);
      expect(commitAuthorElement.querySelector('img.avatar').getAttribute('title')).toEqual(pipeline.commit.author.username);
    });
  });

  describe('commit column', () => {
    it('should render link to commit', () => {
      expect(
        component.$el.querySelector('td:nth-child(3) .commit-id').getAttribute('href'),
      ).toEqual(pipeline.commit.commit_path);
    });
  });

  describe('stages column', () => {
    it('should render an icon for each stage', () => {
      expect(
        component.$el.querySelectorAll('td:nth-child(4) .js-builds-dropdown-button').length,
      ).toEqual(pipeline.details.stages.length);
    });
  });

  describe('actions column', () => {
    it('should render the provided actions', () => {
      expect(
        component.$el.querySelectorAll('td:nth-child(6) ul li').length,
      ).toEqual(pipeline.details.manual_actions.length);
    });
  });
});
