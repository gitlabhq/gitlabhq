import Vue from 'vue';
import tableRowComp from '~/vue_shared/components/pipelines_table_row';
import pipeline from '../../commit/pipelines/mock_data';

describe('Pipelines Table Row', () => {
  const postActionSpy = jasmine.createSpy('spy').and.returnValue(Promise.resolve());

  beforeEach(() => {
    const PipelinesTableRowComponent = Vue.extend(tableRowComp);

    this.component = new PipelinesTableRowComponent({
      el: document.querySelector('.test-dom-element'),
      propsData: {
        pipeline,
        service: {
          postAction: postActionSpy,
        },
      },
    }).$mount();
  });

  it('should render a table row', () => {
    expect(this.component.$el).toEqual('TR');
  });

  describe('status column', () => {
    it('should render a pipeline link', () => {
      expect(
        this.component.$el.querySelector('td.commit-link a').getAttribute('href'),
      ).toEqual(pipeline.path);
    });

    it('should render status text', () => {
      expect(
        this.component.$el.querySelector('td.commit-link a').textContent,
      ).toContain(pipeline.details.status.text);
    });
  });

  describe('information column', () => {
    it('should render a pipeline link', () => {
      expect(
        this.component.$el.querySelector('td:nth-child(2) a').getAttribute('href'),
      ).toEqual(pipeline.path);
    });

    it('should render pipeline ID', () => {
      expect(
        this.component.$el.querySelector('td:nth-child(2) a > span').textContent,
      ).toEqual(`#${pipeline.id}`);
    });

    describe('when a user is provided', () => {
      it('should render user information', () => {
        expect(
          this.component.$el.querySelector('td:nth-child(2) a:nth-child(3)').getAttribute('href'),
        ).toEqual(pipeline.user.web_url);

        expect(
          this.component.$el.querySelector('td:nth-child(2) img').getAttribute('title'),
        ).toEqual(pipeline.user.name);
      });
    });
  });

  describe('commit column', () => {
    it('should render link to commit', () => {
      expect(
        this.component.$el.querySelector('td:nth-child(3) .commit-id').getAttribute('href'),
      ).toEqual(pipeline.commit.commit_path);
    });
  });

  describe('stages column', () => {
    it('should render an icon for each stage', () => {
      expect(
        this.component.$el.querySelectorAll('td:nth-child(4) .js-builds-dropdown-button').length,
      ).toEqual(pipeline.details.stages.length);
    });
  });

  fdescribe('actions column', () => {
    it('should render the provided actions', () => {
      expect(this.component.$el.querySelectorAll('td:nth-child(6) ul li').length)
        .toEqual(pipeline.details.manual_actions.length);
    });

    it('renders the cancel button', () => {
      expect(this.component.$el.querySelectorAll('.js-pipelines-cancel-button')).not.toBeNull();
    });

    it('renders the retry button', () => {
      expect(this.component.$el.querySelectorAll('.js-pipelines-retry-button')).not.toBeNull();
    });
  });

  describe('async button action methods', () => {
    beforeEach(() => {
      spyOn(window, 'confirm').and.returnValue(true);
    });

    it('#resetRequestingState resets isCancelling', (done) => {
      this.component.isCancelling = true;

      this.component.resetRequestingState();

      Vue.nextTick(() => {
        expect(this.component.isCancelling).toBe(false);
        done();
      });
    });

    it('#resetRequestingState resets isRetrying', (done) => {
      this.component.isRetrying = true;

      this.component.resetRequestingState();

      Vue.nextTick(() => {
        expect(this.component.isRetrying).toBe(false);
        done();
      });
    });

    it('#cancelPipeline sets isCancelling', (done) => {
      spyOn(this.component, 'makeRequest');

      this.component.cancelPipeline();

      Vue.nextTick(() => {
        expect(this.component.isCancelling).toBe(true);
        done();
      });
    });

    it('#cancelPipeline calls makeRequest', (done) => {
      spyOn(this.component, 'makeRequest');

      this.component.cancelPipeline();

      Vue.nextTick(() => {
        expect(this.component.makeRequest).toHaveBeenCalled();
        done();
      });
    });

    it('#retryPipeline sets isRetrying', (done) => {
      spyOn(this.component, 'makeRequest');

      this.component.retryPipeline();

      Vue.nextTick(() => {
        expect(this.component.isRetrying).toBe(true);
        done();
      });
    });

    it('#retryPipeline calls makeRequest', (done) => {
      spyOn(this.component, 'makeRequest');

      this.component.retryPipeline();

      Vue.nextTick(() => {
        expect(this.component.makeRequest).toHaveBeenCalled();
        done();
      });
    });


    it('pipeline cancelable update triggers watcher to reset isCancelling', (done) => {
      this.isCancelling = true;
      this.component.$props.pipeline = Object.assign({}, pipeline, { flags: { cancelable: false } });

      Vue.nextTick(() => {
        expect(this.component.isCancelling).toBe(false);
        done();
      });
    });

    it('pipeline retryable update triggers watcher to reset isRetrying', (done) => {
      this.isRetrying = true;
      this.component.$props.pipeline = Object.assign({}, pipeline, { flags: { retryable: false } });

      Vue.nextTick(() => {
        expect(this.component.isRetrying).toBe(false);
        done();
      });
    });
  });
});
