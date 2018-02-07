import Vue from 'vue';
import htmlOutput from '~/notebook/cells/output/html.vue';
import sanitizeTests from './html_sanitize_tests';

describe('html output cell', () => {
  function createComponent(rawCode) {
    const Component = Vue.extend(htmlOutput);

    return new Component({
      propsData: {
        rawCode,
      },
    }).$mount();
  }

  describe('sanitizes output', () => {
    Object.keys(sanitizeTests).forEach((key) => {
      it(key, () => {
        const test = sanitizeTests[key];
        const vm = createComponent(test.input);
        const outputEl = [...vm.$el.querySelectorAll('div')].pop();

        expect(outputEl.innerHTML).toEqual(test.output);

        vm.$destroy();
      });
    });
  });
});
