import $ from 'jquery';
import Vue from 'vue';
import tooltip from '~/vue_shared/directives/tooltip';

describe('Tooltip directive', () => {
  let vm;

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with a single tooltip', () => {
    beforeEach(() => {
      const SomeComponent = Vue.extend({
        directives: {
          tooltip,
        },
        template: `
          <div
            v-tooltip
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
        directives: {
          tooltip,
        },
        template: `
          <div>
            <div
              v-tooltip
              class="js-look-for-tooltip"
              title="foo">
            </div>
            <div
              v-tooltip
              title="bar">
            </div>
          </div>
        `,
      });

      vm = new SomeComponent().$mount();
    });

    it('should have tooltip plugin applied to all instances', () => {
      expect($(vm.$el).find('.js-look-for-tooltip').data('bs.tooltip')).toBeDefined();
    });
  });
});
