import { mountComponentWithRender } from 'spec/helpers/vue_mount_component_helper';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';

const TEST_TITLE = 'lorem-ipsum-dolar-sit-amit-consectur-adipiscing-elit-sed-do';
const CLASS_SHOW_TOOLTIP = 'js-show-tooltip';
const STYLE_TRUNCATED = {
  display: 'inline-block',
  'max-width': '20px',
};
const STYLE_NORMAL = {
  display: 'inline-block',
  'max-width': '1000px',
};

function mountTooltipOnTruncate(options, createChildren) {
  return mountComponentWithRender(h => h(TooltipOnTruncate, options, createChildren(h)), '#app');
}

describe('TooltipOnTruncate component', () => {
  let vm;

  beforeEach(() => {
    const el = document.createElement('div');
    el.id = 'app';
    document.body.appendChild(el);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with default target', () => {
    it('renders tooltip if truncated', done => {
      const options = {
        style: STYLE_TRUNCATED,
        props: {
          title: TEST_TITLE,
        },
      };

      vm = mountTooltipOnTruncate(options, () => [TEST_TITLE]);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el).toHaveClass(CLASS_SHOW_TOOLTIP);
          expect(vm.$el).toHaveData('original-title', TEST_TITLE);
          expect(vm.$el).toHaveData('placement', 'top');
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not render tooltip if normal', done => {
      const options = {
        style: STYLE_NORMAL,
        props: {
          title: TEST_TITLE,
        },
      };

      vm = mountTooltipOnTruncate(options, () => [TEST_TITLE]);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el).not.toHaveClass(CLASS_SHOW_TOOLTIP);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with child target', () => {
    it('renders tooltip if truncated', done => {
      const options = {
        style: STYLE_NORMAL,
        props: {
          title: TEST_TITLE,
          truncateTarget: 'child',
        },
      };

      vm = mountTooltipOnTruncate(options, (h) => [
        h('a', { style: STYLE_TRUNCATED }, TEST_TITLE),
      ]);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el).toHaveClass(CLASS_SHOW_TOOLTIP);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not render tooltip if normal', done => {
      const options = {
        props: {
          title: TEST_TITLE,
          truncateTarget: 'child',
        },
      };

      vm = mountTooltipOnTruncate(options, (h) => [
        h('a', { style: STYLE_NORMAL }, TEST_TITLE),
      ]);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el).not.toHaveClass(CLASS_SHOW_TOOLTIP);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('with fn target', () => {
    it('renders tooltip if truncated', done => {
      const options = {
        style: STYLE_NORMAL,
        props: {
          title: TEST_TITLE,
          truncateTarget: (el) => el.childNodes[1],
        },
      };

      vm = mountTooltipOnTruncate(options, (h) => [
        h('a', { style: STYLE_NORMAL }, TEST_TITLE),
        h('span', { style: STYLE_TRUNCATED }, TEST_TITLE),
      ]);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el).toHaveClass(CLASS_SHOW_TOOLTIP);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('placement', () => {
    it('sets data-placement when tooltip is rendered', done => {
      const options = {
        props: {
          title: TEST_TITLE,
          truncateTarget: 'child',
          placement: 'bottom',
        },
      };

      vm = mountTooltipOnTruncate(options, (h) => [
        h('a', { style: STYLE_TRUNCATED }, TEST_TITLE),
      ]);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el).toHaveClass(CLASS_SHOW_TOOLTIP);
          expect(vm.$el).toHaveData('placement', options.props.placement);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
