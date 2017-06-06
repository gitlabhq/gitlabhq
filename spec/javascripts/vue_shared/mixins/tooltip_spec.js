import Vue from 'vue';
import tooltipMixin from '~/vue_shared/mixins/tooltip';

describe('Tooltip mixin', () => {
  let vm;

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with a single tooltip', () => {
    beforeEach(() => {
      const SomeComponent = Vue.extend({
        mixins: [
          tooltipMixin,
        ],
        template: `
          <div
            class="js-vue-tooltip"
            title="foo">
          </div>
        `,
      });

      vm = new SomeComponent().$mount();
    });

    it('should have tooltip plugin applied', () => {
      expect($(vm.$el).data('bs.tooltip')).toBeDefined();
    });
  });

  describe('with multiple tooltips', () => {
    beforeEach(() => {
      const SomeComponent = Vue.extend({
        mixins: [
          tooltipMixin,
        ],
        template: `
          <div>
            <div
              class="js-vue-tooltip"
              title="foo">
            </div>
            <div
              class="js-vue-tooltip"
              title="bar">
            </div>
          </div>
        `,
      });

      vm = new SomeComponent().$mount();
    });

    it('should have tooltip plugin applied to all instances', () => {
      expect($(vm.$el).find('.js-vue-tooltip').data('bs.tooltip')).toBeDefined();
    });
  });
});
