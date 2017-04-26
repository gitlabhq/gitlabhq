import Vue from 'vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

describe('Vue translate filter', () => {
  let el;

  beforeEach(() => {
    el = document.createElement('div');

    document.body.appendChild(el);
  });

  it('translate single text', (done) => {
    const comp = new Vue({
      el,
      template: `
        <span>
          {{ __('testing') }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(
        comp.$el.textContent.trim(),
      ).toBe('testing');

      done();
    });
  });

  it('translate plural text with single count', (done) => {
    const comp = new Vue({
      el,
      template: `
        <span>
          {{ n__('%d day', '%d days', 1) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(
        comp.$el.textContent.trim(),
      ).toBe('1 day');

      done();
    });
  });

  it('translate plural text with multiple count', (done) => {
    const comp = new Vue({
      el,
      template: `
        <span>
          {{ n__('%d day', '%d days', 2) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(
        comp.$el.textContent.trim(),
      ).toBe('2 days');

      done();
    });
  });

  it('translate plural without replacing any text', (done) => {
    const comp = new Vue({
      el,
      template: `
        <span>
          {{ n__('day', 'days', 2) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(
        comp.$el.textContent.trim(),
      ).toBe('days');

      done();
    });
  });
});
