import Vue from 'vue';
import Icon from '~/vue_shared/components/icon.vue';

const IconComponent = Vue.extend(Icon);

describe('Sprite Icon Component', function () {
  describe('Initialization', function () {
    beforeEach(function () {
      this.propsData = {
        name: 'test',
        size: 99,
        cssClasses: 'extraclasses',
      };

      this.icon = new IconComponent({
        propsData: this.propsData,
      }).$mount();
    });

    it('should return a defined Vue component', function () {
      expect(this.icon).toBeDefined();
    });

    it('should have <svg> as a child element', function () {
      expect(this.icon.$el.tagName).toBe('svg');
    });

    it('should have <use> as a child element with the correct href', function () {
      expect(this.icon.$el.firstChild.tagName).toBe('use');
      expect(this.icon.$el.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_icons}#test`);
    });

    it('should properly compute iconSizeClass', function () {
      expect(this.icon.iconSizeClass).toBe('s99');
    });

    it('should properly render img css', function () {
      const classList = this.icon.$el.classList;
      const containsSizeClass = classList.contains('s99');
      const containsCustomClass = classList.contains('extraclasses');
      expect(containsSizeClass).toBe(true);
      expect(containsCustomClass).toBe(true);
    });
  });
});
