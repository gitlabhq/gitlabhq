import Vue from 'vue';
import CiStatusIconLink from '~/vue_shared/components/ci_status_icon_link';

describe('CI Status Icon Link Component', () => {
  beforeEach(() => {
    const CiStatusIconLinkComponent = Vue.extend(CiStatusIconLink);

    this.component = new CiStatusIconLinkComponent({
      propsData: {
        status: 'failed',
        href: '/a-wop/dop-a-doo/dop',
        borderless: true,
      },
    }).$mount();
  });

  describe('setup', () => {
    it('initializes props', () => {
      expect(this.component.status).toBe('failed');
      expect(this.component.href).toBe('/a-wop/dop-a-doo/dop');
      expect(this.component.borderless).toBe(true);
    });
  });

  describe('#ciStatusClasses', () => {
    it('contains "ci-status"', () => {
      expect(this.component.ciStatusClasses).toContain('ci-status');
    });

    it('contains computed ci status', () => {
      expect(this.component.ciStatusClasses).toContain('ci-failed');
    });
  });

  describe('#statusSvg', () => {
    it('contains svg html', () => {
      expect(this.component.statusSvg).toContain('<svg');
    });
  });

  describe('#iconSvg', () => {
    it('contains status text', () => {
      expect(this.component.iconSvg).toContain('failed');
    });

    it('contains svg html', () => {
      expect(this.component.iconSvg).toContain('<svg');
    });
  });

  describe('rendered output', () => {
    it('contains link tag', () => {
      expect(this.component.$el.tagName).toBe('A');
    });

    it('contains correct classes', () => {
      expect(this.component.$el.className).toBe('ci-status ci-failed');
    });

    it('contains two child nodes', () => {
      expect(this.component.$el.childNodes.length).toBe(2);
    });

    it('contains svg first', () => {
      expect(this.component.$el.childNodes[0].tagName).toBe('svg');
    });

    it('contains text second', () => {
      expect(this.component.$el.childNodes[1].nodeName).toBe('#text');
    });
  });
});

