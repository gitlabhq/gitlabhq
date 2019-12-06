import Vue from 'vue';
import Jed from 'jed';

import { trimText } from 'spec/helpers/text_helper';
import locale from '~/locale';
import Translate from '~/vue_shared/translate';

describe('Vue translate filter', () => {
  let el;

  const createTranslationMock = (key, ...translations) => {
    const fakeLocale = new Jed({
      domain: 'app',
      locale_data: {
        app: {
          '': {
            domain: 'app',
            lang: 'vo',
            plural_forms: 'nplurals=2; plural=(n != 1);',
          },
          [key]: translations,
        },
      },
    });

    // eslint-disable-next-line no-underscore-dangle
    locale.__Rewire__('locale', fakeLocale);
  };

  afterEach(() => {
    // eslint-disable-next-line no-underscore-dangle
    locale.__ResetDependency__('locale');
  });

  beforeEach(() => {
    Vue.use(Translate);

    el = document.createElement('div');

    document.body.appendChild(el);
  });

  it('translate singular text (`__`)', done => {
    const key = 'singular';
    const translation = 'singular_translated';
    createTranslationMock(key, translation);

    const vm = new Vue({
      el,
      template: `
        <span>
          {{ __('${key}') }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(trimText(vm.$el.textContent)).toBe(translation);

      done();
    });
  });

  it('translate plural text (`n__`) without any substituting text', done => {
    const key = 'plural';
    const translationPlural = 'plural_multiple translation';
    createTranslationMock(key, 'plural_singular translation', translationPlural);

    const vm = new Vue({
      el,
      template: `
        <span>
          {{ n__('${key}', 'plurals', 2) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(trimText(vm.$el.textContent)).toBe(translationPlural);

      done();
    });
  });

  describe('translate plural text (`n__`) with substituting %d', () => {
    const key = '%d day';

    beforeEach(() => {
      createTranslationMock(key, '%d singular translated', '%d plural translated');
    });

    it('and n === 1', done => {
      const vm = new Vue({
        el,
        template: `
        <span>
          {{ n__('${key}', '%d days', 1) }}
        </span>
      `,
      }).$mount();

      Vue.nextTick(() => {
        expect(trimText(vm.$el.textContent)).toBe('1 singular translated');

        done();
      });
    });

    it('and n > 1', done => {
      const vm = new Vue({
        el,
        template: `
        <span>
          {{ n__('${key}', '%d days', 2) }}
        </span>
      `,
      }).$mount();

      Vue.nextTick(() => {
        expect(trimText(vm.$el.textContent)).toBe('2 plural translated');

        done();
      });
    });
  });

  describe('translates text with context `s__`', () => {
    const key = 'Context|Foobar';
    const translation = 'Context|Foobar translated';
    const expectation = 'Foobar translated';

    beforeEach(() => {
      createTranslationMock(key, translation);
    });

    it('and using two parameters', done => {
      const vm = new Vue({
        el,
        template: `
        <span>
          {{ s__('Context', 'Foobar') }}
        </span>
      `,
      }).$mount();

      Vue.nextTick(() => {
        expect(trimText(vm.$el.textContent)).toBe(expectation);

        done();
      });
    });

    it('and using the pipe syntax', done => {
      const vm = new Vue({
        el,
        template: `
        <span>
          {{ s__('${key}') }}
        </span>
      `,
      }).$mount();

      Vue.nextTick(() => {
        expect(trimText(vm.$el.textContent)).toBe(expectation);

        done();
      });
    });
  });

  it('translate multi line text', done => {
    const translation = 'multiline string translated';
    createTranslationMock('multiline string', translation);

    const vm = new Vue({
      el,
      template: `
        <span>
          {{ __(\`
          multiline
          string
          \`) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(trimText(vm.$el.textContent)).toBe(translation);

      done();
    });
  });

  it('translate pluralized multi line text', done => {
    const translation = 'multiline string plural';

    createTranslationMock('multiline string', 'multiline string singular', translation);

    const vm = new Vue({
      el,
      template: `
        <span>
          {{ n__(
          \`
          multiline
          string
          \`,
          \`
          multiline
          strings
          \`,
          2
          ) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(trimText(vm.$el.textContent)).toBe(translation);

      done();
    });
  });

  it('translate pluralized multi line text with context', done => {
    const translation = 'multiline string with context';

    createTranslationMock('Context| multiline string', translation);

    const vm = new Vue({
      el,
      template: `
        <span>
          {{ s__(
          \`
          Context|
          multiline
          string
          \`
          ) }}
        </span>
      `,
    }).$mount();

    Vue.nextTick(() => {
      expect(trimText(vm.$el.textContent)).toBe(translation);

      done();
    });
  });
});
