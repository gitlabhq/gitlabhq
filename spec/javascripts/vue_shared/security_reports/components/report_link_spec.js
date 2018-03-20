import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/report_link.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('report link', () => {
  let vm;

  const Component = Vue.extend(component);

  afterEach(() => {
    vm.$destroy();
  });

  describe('With url', () => {
    it('renders link', () => {
      vm = mountComponent(Component, {
        issue: {
          path: 'Gemfile.lock',
          urlPath: '/Gemfile.lock',
        },
      });

      expect(vm.$el.textContent.trim()).toContain('in');
      expect(vm.$el.querySelector('a').getAttribute('href')).toEqual('/Gemfile.lock');
      expect(vm.$el.querySelector('a').textContent.trim()).toEqual('Gemfile.lock');
    });
  });

  describe('Without url', () => {
    it('does not render link', () => {
      vm = mountComponent(Component, {
        issue: {
          path: 'Gemfile.lock',
        },
      });

      expect(vm.$el.querySelector('a')).toBeNull();
      expect(vm.$el.textContent.trim()).toContain('in');
      expect(vm.$el.textContent.trim()).toContain('Gemfile.lock');
    });
  });

  describe('with line', () => {
    it('renders line  number', () => {
      vm = mountComponent(Component, {
        issue: {
          path: 'Gemfile.lock',
          urlPath:
            'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
          line: 22,
        },
      });

      expect(vm.$el.querySelector('a').textContent.trim()).toContain('Gemfile.lock:22');
    });
  });

  describe('without line', () => {
    it('does not render line  number', () => {
      vm = mountComponent(Component, {
        issue: {
          path: 'Gemfile.lock',
          urlPath:
            'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
        },
      });

      expect(vm.$el.querySelector('a').textContent.trim()).not.toContain(':22');
    });
  });
});
