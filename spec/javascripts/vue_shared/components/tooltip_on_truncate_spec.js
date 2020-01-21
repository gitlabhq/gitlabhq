import { shallowMount, createLocalVue } from '@vue/test-utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

const TEST_TITLE = 'lorem-ipsum-dolar-sit-amit-consectur-adipiscing-elit-sed-do';
const STYLE_TRUNCATED = 'display: inline-block; max-width: 20px;';
const STYLE_NORMAL = 'display: inline-block; max-width: 1000px;';

const localVue = createLocalVue();

const createElementWithStyle = (style, content) => `<a href="#" style="${style}">${content}</a>`;

describe('TooltipOnTruncate component', () => {
  let wrapper;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(localVue.extend(TooltipOnTruncate), {
      localVue,
      attachToDocument: true,
      propsData: {
        title: TEST_TITLE,
        ...propsData,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const hasTooltip = () => wrapper.classes('js-show-tooltip');

  describe('with default target', () => {
    it('renders tooltip if truncated', done => {
      createComponent({
        attrs: {
          style: STYLE_TRUNCATED,
        },
        slots: {
          default: [TEST_TITLE],
        },
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(hasTooltip()).toBe(true);
          expect(wrapper.attributes('data-original-title')).toEqual(TEST_TITLE);
          expect(wrapper.attributes('data-placement')).toEqual('top');
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not render tooltip if normal', done => {
      createComponent({
        attrs: {
          style: STYLE_NORMAL,
        },
        slots: {
          default: [TEST_TITLE],
        },
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(hasTooltip()).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with child target', () => {
    it('renders tooltip if truncated', done => {
      createComponent({
        attrs: {
          style: STYLE_NORMAL,
        },
        propsData: {
          truncateTarget: 'child',
        },
        slots: {
          default: createElementWithStyle(STYLE_TRUNCATED, TEST_TITLE),
        },
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(hasTooltip()).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not render tooltip if normal', done => {
      createComponent({
        propsData: {
          truncateTarget: 'child',
        },
        slots: {
          default: createElementWithStyle(STYLE_NORMAL, TEST_TITLE),
        },
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(hasTooltip()).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with fn target', () => {
    it('renders tooltip if truncated', done => {
      createComponent({
        attrs: {
          style: STYLE_NORMAL,
        },
        propsData: {
          truncateTarget: el => el.childNodes[1],
        },
        slots: {
          default: [
            createElementWithStyle('', TEST_TITLE),
            createElementWithStyle(STYLE_TRUNCATED, TEST_TITLE),
          ],
        },
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(hasTooltip()).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('placement', () => {
    it('sets data-placement when tooltip is rendered', done => {
      const placement = 'bottom';

      createComponent({
        propsData: {
          placement,
        },
        attrs: {
          style: STYLE_TRUNCATED,
        },
        slots: {
          default: TEST_TITLE,
        },
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(hasTooltip()).toBe(true);
          expect(wrapper.attributes('data-placement')).toEqual(placement);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
