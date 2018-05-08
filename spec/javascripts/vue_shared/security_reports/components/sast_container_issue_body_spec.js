import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/sast_container_issue_body.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('sast container issue body', () => {
  let vm;

  const Component = Vue.extend(component);

  const sastContainerIssue = {
    name: 'CVE-2017-11671',
    nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-11671',
    namespace: 'debian:8',
    path: 'debian:8',
    priority: 'Low',
    severity: 'Low',
    vulnerability: 'CVE-2017-11671',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('with priority', () => {
    it('renders priority key', () => {
      vm = mountComponent(Component, {
        issue: sastContainerIssue,
      });

      expect(vm.$el.textContent.trim()).toContain(sastContainerIssue.priority);
    });
  });

  describe('without priority', () => {
    it('does not rendere priority key', () => {
      const issueCopy = Object.assign({}, sastContainerIssue);
      delete issueCopy.priority;

      vm = mountComponent(Component, {
        issue: issueCopy,
      });

      expect(vm.$el.textContent.trim()).not.toContain(sastContainerIssue.priority);
    });
  });

  it('renders name', () => {
    vm = mountComponent(Component, {
      issue: sastContainerIssue,
    });

    expect(vm.$el.querySelector('button').textContent.trim()).toEqual(sastContainerIssue.name);
  });

  describe('path', () => {
    it('renders path', () => {
      vm = mountComponent(Component, {
        issue: sastContainerIssue,
      });

      expect(vm.$el.textContent.trim()).toContain(sastContainerIssue.path);
    });
  });
});
