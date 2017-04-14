import Vue from 'vue';
import { borderlessIcons } from '~/vue_shared/utils/ci_status_svg_index';
import Stage from '~/vue_pipelines_index/components/stage';

const SUCCESS_SVG = borderlessIcons.success;

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
    describe('stageStatusSvg', function () {
      let stage;
      let stageStatusSvg;

      beforeEach(() => {
        stage = { stage: { status: { icon: 'icon_status_success' } } };

        stageStatusSvg = Stage.computed.stageStatusSvg.call(stage);
      });

      it("should return the correct icon for the stage's status", () => {
        expect(stageStatusSvg).toBe(SUCCESS_SVG);
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
});
