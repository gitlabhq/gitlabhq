import Vue from 'vue';
import { SUCCESS_SVG } from '~/ci_status_icons';
import Stage from '~/pipelines/components/stage';

function minify(string) {
  return string.replace(/\s/g, '');
}

describe('Pipelines Stage', () => {
  describe('data', () => {
    let stageReturnValue;

    beforeEach(() => {
      stageReturnValue = Stage.data();
    });

    it('should return object with .builds and .spinner', () => {
      expect(stageReturnValue).toEqual({
        builds: '',
        spinner: '<span class="fa fa-spinner fa-spin"></span>',
      });
    });
  });

  describe('computed', () => {
    describe('svgHTML', function () {
      let stage;
      let svgHTML;

      beforeEach(() => {
        stage = { stage: { status: { icon: 'icon_status_success' } } };

        svgHTML = Stage.computed.svgHTML.call(stage);
      });

      it("should return the correct icon for the stage's status", () => {
        expect(svgHTML).toBe(SUCCESS_SVG);
      });
    });
  });

  describe('when mounted', () => {
    let StageComponent;
    let renderedComponent;
    let stage;

    beforeEach(() => {
      stage = { status: { icon: 'icon_status_success' } };

      StageComponent = Vue.extend(Stage);

      renderedComponent = new StageComponent({
        propsData: {
          stage,
        },
      }).$mount();
    });

    it('should render the correct status svg', () => {
      const minifiedComponent = minify(renderedComponent.$el.outerHTML);
      const expectedSVG = minify(SUCCESS_SVG);

      expect(minifiedComponent).toContain(expectedSVG);
    });
  });

  describe('when request fails', () => {
    it('closes dropdown', () => {
      spyOn($, 'ajax').and.callFake(options => options.error());
      const StageComponent = Vue.extend(Stage);

      const component = new StageComponent({
        propsData: { stage: { status: { icon: 'foo' } } },
      }).$mount();

      expect(
        component.$el.classList.contains('open'),
      ).toEqual(false);
    });
  });
});
