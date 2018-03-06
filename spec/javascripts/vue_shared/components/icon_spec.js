import Vue from 'vue';
import Icon from '~/vue_shared/components/icon.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Sprite Icon Component', function () {
  describe('Initialization', function () {
    let icon;

    beforeEach(function () {
      const IconComponent = Vue.extend(Icon);

      icon = mountComponent(IconComponent, {
        name: 'test',
        size: 32,
        cssClasses: 'extraclasses',
      });
    });

    afterEach(() => {
      icon.$destroy();
    });

    it('should return a defined Vue component', function () {
      expect(icon).toBeDefined();
    });

    it('should have <svg> as a child element', function () {
      expect(icon.$el.tagName).toBe('svg');
    });

    it('should have <use> as a child element with the correct href', function () {
      expect(icon.$el.firstChild.tagName).toBe('use');
      expect(icon.$el.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_icons}#test`);
    });

    it('should properly compute iconSizeClass', function () {
      expect(icon.iconSizeClass).toBe('s32');
    });

    it('forbids invalid size prop', () => {
      expect(icon.$options.props.size.validator(NaN)).toBeFalsy();
      expect(icon.$options.props.size.validator(0)).toBeFalsy();
      expect(icon.$options.props.size.validator(9001)).toBeFalsy();
    });

    it('should properly render img css', function () {
      const classList = icon.$el.classList;
      const containsSizeClass = classList.contains('s32');
      const containsCustomClass = classList.contains('extraclasses');
      expect(containsSizeClass).toBe(true);
      expect(containsCustomClass).toBe(true);
    });
  });
});
