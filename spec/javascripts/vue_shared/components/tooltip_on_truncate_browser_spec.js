// this file can't be migrated to jest because it relies on the browser to perform integration tests:
// (specifically testing around css properties `overflow` and `white-space`)
// see: https://gitlab.com/groups/gitlab-org/-/epics/895#what-if-theres-a-karma-spec-which-is-simply-unmovable-to-jest-ie-it-is-dependent-on-a-running-browser-environment

import { mount, shallowMount } from '@vue/test-utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

const TEXT_SHORT = 'lorem';
const TEXT_LONG = 'lorem-ipsum-dolar-sit-amit-consectur-adipiscing-elit-sed-do';

const TEXT_TRUNCATE = 'white-space: nowrap; overflow:hidden;';
const STYLE_NORMAL = `${TEXT_TRUNCATE} display: inline-block; max-width: 1000px;`; // does not overflows
const STYLE_OVERFLOWED = `${TEXT_TRUNCATE} display: inline-block; max-width: 50px;`; // overflowed when text is long

const createElementWithStyle = (style, content) => `<a href="#" style="${style}">${content}</a>`;

describe('TooltipOnTruncate component', () => {
  let wrapper;
  let parent;

  const createComponent = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(TooltipOnTruncate, {
      attachToDocument: true,
      propsData: {
        ...propsData,
      },
      attrs: {
        style: STYLE_OVERFLOWED,
      },
      ...options,
    });
  };

  const createWrappedComponent = ({ propsData, ...options }) => {
    // set a parent around the tested component
    parent = mount(
      {
        props: {
          title: { default: '' },
        },
        template: `
        <TooltipOnTruncate :title="title" truncate-target="child" style="${STYLE_OVERFLOWED}">
          <div>{{title}}</div>
        </TooltipOnTruncate>
        `,
        components: {
          TooltipOnTruncate,
        },
      },
      {
        propsData: { ...propsData },
        attachToDocument: true,
        ...options,
      },
    );

    wrapper = parent.find(TooltipOnTruncate);
  };

  const hasTooltip = () => wrapper.classes('js-show-tooltip');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with default target', () => {
    it('renders tooltip if truncated', () => {
      createComponent({
        propsData: {
          title: TEXT_LONG,
        },
        slots: {
          default: [TEXT_LONG],
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(true);
        expect(wrapper.attributes('data-original-title')).toEqual(TEXT_LONG);
        expect(wrapper.attributes('data-placement')).toEqual('top');
      });
    });

    it('does not render tooltip if normal', () => {
      createComponent({
        propsData: {
          title: TEXT_SHORT,
        },
        slots: {
          default: [TEXT_SHORT],
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(false);
      });
    });
  });

  describe('with child target', () => {
    it('renders tooltip if truncated', () => {
      createComponent({
        attrs: {
          style: STYLE_NORMAL,
        },
        propsData: {
          title: TEXT_LONG,
          truncateTarget: 'child',
        },
        slots: {
          default: createElementWithStyle(STYLE_OVERFLOWED, TEXT_LONG),
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(true);
      });
    });

    it('does not render tooltip if normal', () => {
      createComponent({
        propsData: {
          truncateTarget: 'child',
        },
        slots: {
          default: createElementWithStyle(STYLE_NORMAL, TEXT_LONG),
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(false);
      });
    });
  });

  describe('with fn target', () => {
    it('renders tooltip if truncated', () => {
      createComponent({
        attrs: {
          style: STYLE_NORMAL,
        },
        propsData: {
          title: TEXT_LONG,
          truncateTarget: el => el.childNodes[1],
        },
        slots: {
          default: [
            createElementWithStyle('', TEXT_LONG),
            createElementWithStyle(STYLE_OVERFLOWED, TEXT_LONG),
          ],
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(true);
      });
    });
  });

  describe('placement', () => {
    it('sets data-placement when tooltip is rendered', () => {
      const placement = 'bottom';

      createComponent({
        propsData: {
          placement,
        },
        attrs: {
          style: STYLE_OVERFLOWED,
        },
        slots: {
          default: TEXT_LONG,
        },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(hasTooltip()).toBe(true);
        expect(wrapper.attributes('data-placement')).toEqual(placement);
      });
    });
  });

  describe('updates when title and slot content changes', () => {
    describe('is initialized with a long text', () => {
      beforeEach(() => {
        createWrappedComponent({
          propsData: { title: TEXT_LONG },
        });
        return parent.vm.$nextTick();
      });

      it('renders tooltip', () => {
        expect(hasTooltip()).toBe(true);
        expect(wrapper.attributes('data-original-title')).toEqual(TEXT_LONG);
        expect(wrapper.attributes('data-placement')).toEqual('top');
      });

      it('does not render tooltip after updated to a short text', () => {
        parent.setProps({
          title: TEXT_SHORT,
        });

        return wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.$nextTick()) // wait 2 times to get an updated slot
          .then(() => {
            expect(hasTooltip()).toBe(false);
          });
      });
    });

    describe('is initialized with a short text', () => {
      beforeEach(() => {
        createWrappedComponent({
          propsData: { title: TEXT_SHORT },
        });
        return wrapper.vm.$nextTick();
      });

      it('does not render tooltip', () => {
        expect(hasTooltip()).toBe(false);
      });

      it('renders tooltip after updated to a long text', () => {
        parent.setProps({
          title: TEXT_LONG,
        });

        return wrapper.vm
          .$nextTick()
          .then(() => wrapper.vm.$nextTick()) // wait 2 times to get an updated slot
          .then(() => {
            expect(hasTooltip()).toBe(true);
            expect(wrapper.attributes('data-original-title')).toEqual(TEXT_LONG);
            expect(wrapper.attributes('data-placement')).toEqual('top');
          });
      });
    });
  });
});
