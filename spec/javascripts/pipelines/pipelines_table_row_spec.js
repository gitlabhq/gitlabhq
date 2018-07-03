import Vue from 'vue';
import tableRowComp from '~/pipelines/components/pipelines_table_row.vue';
import eventHub from '~/pipelines/event_hub';

describe('Pipelines Table Row', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';
  const buildComponent = pipeline => {
    const PipelinesTableRowComponent = Vue.extend(tableRowComp);
    return new PipelinesTableRowComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        pipeline,
        autoDevopsHelpPath: 'foo',
        viewType: 'root',
      },
    }).$mount();
  };

  let component;
  let pipeline;
  let pipelineWithoutAuthor;
  let pipelineWithoutCommit;

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    const { pipelines } = getJSONFixture(jsonFixtureName);

    pipeline = pipelines.find(p => p.user !== null && p.commit !== null);
    pipelineWithoutAuthor = pipelines.find(p => p.user === null && p.commit !== null);
    pipelineWithoutCommit = pipelines.find(p => p.user === null && p.commit === null);
  });

  afterEach(() => {
    component.$destroy();
  });

  it('should render a table row', () => {
    component = buildComponent(pipeline);
    expect(component.$el.getAttribute('class')).toContain('gl-responsive-table-row');
  });

  describe('status column', () => {
    beforeEach(() => {
      component = buildComponent(pipeline);
    });

    it('should render a pipeline link', () => {
      expect(
        component.$el.querySelector('.table-section.commit-link a').getAttribute('href'),
      ).toEqual(pipeline.path);
    });

    it('should render status text', () => {
      expect(component.$el.querySelector('.table-section.commit-link a').textContent).toContain(
        pipeline.details.status.text,
      );
    });
  });

  describe('information column', () => {
    beforeEach(() => {
      component = buildComponent(pipeline);
    });

    it('should render a pipeline link', () => {
      expect(
        component.$el.querySelector('.table-section:nth-child(2) a').getAttribute('href'),
      ).toEqual(pipeline.path);
    });

    it('should render pipeline ID', () => {
      expect(
        component.$el.querySelector('.table-section:nth-child(2) a > span').textContent,
      ).toEqual(`#${pipeline.id}`);
    });

    describe('when a user is provided', () => {
      it('should render user information', () => {
        expect(
          component.$el
            .querySelector('.table-section:nth-child(2) a:nth-child(3)')
            .getAttribute('href'),
        ).toEqual(pipeline.user.path);

        expect(
          component.$el
            .querySelector('.table-section:nth-child(2) img')
            .getAttribute('data-original-title'),
        ).toEqual(pipeline.user.name);
      });
    });
  });

  describe('commit column', () => {
    it('should render link to commit', () => {
      component = buildComponent(pipeline);

      const commitLink = component.$el.querySelector('.branch-commit .commit-sha');
      expect(commitLink.getAttribute('href')).toEqual(pipeline.commit.commit_path);
    });

    const findElements = () => {
      const commitTitleElement = component.$el.querySelector('.branch-commit .commit-title');
      const commitAuthorElement = commitTitleElement.querySelector('a.avatar-image-container');

      if (!commitAuthorElement) {
        return { commitAuthorElement };
      }

      const commitAuthorLink = commitAuthorElement.getAttribute('href');
      const commitAuthorName = commitAuthorElement
        .querySelector('img.avatar')
        .getAttribute('data-original-title');

      return { commitAuthorElement, commitAuthorLink, commitAuthorName };
    };

    it('renders nothing without commit', () => {
      expect(pipelineWithoutCommit.commit).toBe(null);
      component = buildComponent(pipelineWithoutCommit);

      const { commitAuthorElement } = findElements();

      expect(commitAuthorElement).toBe(null);
    });

    it('renders commit author', () => {
      component = buildComponent(pipeline);
      const { commitAuthorLink, commitAuthorName } = findElements();

      expect(commitAuthorLink).toEqual(pipeline.commit.author.path);
      expect(commitAuthorName).toEqual(pipeline.commit.author.username);
    });

    it('renders commit with unregistered author', () => {
      expect(pipelineWithoutAuthor.commit.author).toBe(null);
      component = buildComponent(pipelineWithoutAuthor);

      const { commitAuthorLink, commitAuthorName } = findElements();

      expect(commitAuthorLink).toEqual(`mailto:${pipelineWithoutAuthor.commit.author_email}`);
      expect(commitAuthorName).toEqual(pipelineWithoutAuthor.commit.author_name);
    });
  });

  describe('stages column', () => {
    beforeEach(() => {
      component = buildComponent(pipeline);
    });

    it('should render an icon for each stage', () => {
      expect(
        component.$el.querySelectorAll('.table-section:nth-child(4) .js-builds-dropdown-button')
          .length,
      ).toEqual(pipeline.details.stages.length);
    });
  });

  describe('actions column', () => {
    beforeEach(() => {
      const withActions = Object.assign({}, pipeline);
      withActions.flags.cancelable = true;
      withActions.flags.retryable = true;
      withActions.cancel_path = '/cancel';
      withActions.retry_path = '/retry';

      component = buildComponent(withActions);
    });

    it('should render the provided actions', () => {
      expect(component.$el.querySelector('.js-pipelines-retry-button')).not.toBeNull();
      expect(component.$el.querySelector('.js-pipelines-cancel-button')).not.toBeNull();
    });

    it('emits `retryPipeline` event when retry button is clicked and toggles loading', () => {
      eventHub.$on('retryPipeline', endpoint => {
        expect(endpoint).toEqual('/retry');
      });

      component.$el.querySelector('.js-pipelines-retry-button').click();
      expect(component.isRetrying).toEqual(true);
    });

    it('emits `openConfirmationModal` event when cancel button is clicked and toggles loading', () => {
      eventHub.$once('openConfirmationModal', data => {
        expect(data.endpoint).toEqual('/cancel');
        expect(data.pipelineId).toEqual(pipeline.id);
      });

      component.$el.querySelector('.js-pipelines-cancel-button').click();
    });

    it('renders a loading icon when `cancelingPipeline` matches pipeline id', done => {
      component.cancelingPipeline = pipeline.id;
      component.$nextTick()
        .then(() => {
          expect(component.isCancelling).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
