import Vue from 'vue';
import Cookies from 'js-cookie';
import PipelineSchedulesCallout from '~/pages/projects/pipeline_schedules/shared/components/pipeline_schedules_callout.vue';

const PipelineSchedulesCalloutComponent = Vue.extend(PipelineSchedulesCallout);
const cookieKey = 'pipeline_schedules_callout_dismissed';
const docsUrl = 'help/ci/scheduled_pipelines';

describe('Pipeline Schedule Callout', function () {
  beforeEach(() => {
    setFixtures(`
      <div id='pipeline-schedules-callout' data-docs-url=${docsUrl}></div>
    `);
  });

  describe('independent of cookies', () => {
    beforeEach(() => {
      this.calloutComponent = new PipelineSchedulesCalloutComponent().$mount();
    });

    it('the component can be initialized', () => {
      expect(this.calloutComponent).toBeDefined();
    });

    it('correctly sets illustrationSvg', () => {
      expect(this.calloutComponent.illustrationSvg).toContain('<svg');
    });

    it('correctly sets docsUrl', () => {
      expect(this.calloutComponent.docsUrl).toContain(docsUrl);
    });
  });

  describe(`when ${cookieKey} cookie is set`, () => {
    beforeEach(() => {
      Cookies.set(cookieKey, true);
      this.calloutComponent = new PipelineSchedulesCalloutComponent().$mount();
    });

    it('correctly sets calloutDismissed to true', () => {
      expect(this.calloutComponent.calloutDismissed).toBe(true);
    });

    it('does not render the callout', () => {
      expect(this.calloutComponent.$el.childNodes.length).toBe(0);
    });
  });

  describe('when cookie is not set', () => {
    beforeEach(() => {
      Cookies.remove(cookieKey);
      this.calloutComponent = new PipelineSchedulesCalloutComponent().$mount();
    });

    it('correctly sets calloutDismissed to false', () => {
      expect(this.calloutComponent.calloutDismissed).toBe(false);
    });

    it('renders the callout container', () => {
      expect(this.calloutComponent.$el.querySelector('.bordered-box')).not.toBeNull();
    });

    it('renders the callout svg', () => {
      expect(this.calloutComponent.$el.outerHTML).toContain('<svg');
    });

    it('renders the callout title', () => {
      expect(this.calloutComponent.$el.outerHTML).toContain('Scheduling Pipelines');
    });

    it('renders the callout text', () => {
      expect(this.calloutComponent.$el.outerHTML).toContain('runs pipelines in the future');
    });

    it('renders the documentation url', () => {
      expect(this.calloutComponent.$el.outerHTML).toContain(docsUrl);
    });

    it('updates calloutDismissed when close button is clicked', (done) => {
      this.calloutComponent.$el.querySelector('#dismiss-callout-btn').click();

      Vue.nextTick(() => {
        expect(this.calloutComponent.calloutDismissed).toBe(true);
        done();
      });
    });

    it('#dismissCallout updates calloutDismissed', (done) => {
      this.calloutComponent.dismissCallout();

      Vue.nextTick(() => {
        expect(this.calloutComponent.calloutDismissed).toBe(true);
        done();
      });
    });

    it('is hidden when close button is clicked', (done) => {
      this.calloutComponent.$el.querySelector('#dismiss-callout-btn').click();

      Vue.nextTick(() => {
        expect(this.calloutComponent.$el.childNodes.length).toBe(0);
        done();
      });
    });
  });
});
