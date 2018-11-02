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
      setFixtures('<div id="dummy-element"></div>');
      vm = new Vue({
        el: '#dummy-element',
        directives: {
          tooltip,
        },
        data() {
          return {
            tooltip: 'some text',
          };
        },
        template: '<div v-tooltip :title="tooltip"></div>',
      });
    });

    it('should have tooltip plugin applied', () => {
      expect($(vm.$el).data('bs.tooltip')).toBeDefined();
    });

    it('displays the title as tooltip', () => {
      $(vm.$el).tooltip('show');
      const tooltipElement = document.querySelector('.tooltip-inner');

      expect(tooltipElement.innerText).toContain('some text');
    });

    it('updates a visible tooltip', done => {
      $(vm.$el).tooltip('show');
      const tooltipElement = document.querySelector('.tooltip-inner');

      vm.tooltip = 'other text';

      Vue.nextTick()
        .then(() => {
          expect(tooltipElement).toContainText('other text');
          done();
        })
        .catch(done.fail);
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
      expect(
        $(vm.$el)
          .find('.js-look-for-tooltip')
          .data('bs.tooltip'),
      ).toBeDefined();
    });
  });
});
