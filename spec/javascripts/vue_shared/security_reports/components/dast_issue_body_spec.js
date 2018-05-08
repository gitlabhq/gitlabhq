import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/dast_issue_body.vue';
import mountComponent from '../../../helpers/vue_mount_component_helper';

describe('dast issue body', () => {
  let vm;

  const Component = Vue.extend(component);
  const dastIssue = {
    alert: 'X-Content-Type-Options Header Missing',
    confidence: '2',
    count: '17',
    cweid: '16',
    desc:
      '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". </p>',
    name: 'X-Content-Type-Options Header Missing',
    parsedDescription:
      ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
    priority: 'Low (Medium)',
    reference:
      '<p>http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx</p><p>https://www.owasp.org/index.php/List_of_useful_HTTP_headers</p>',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('with priority', () => {
    it('renders priority key', () => {
      vm = mountComponent(Component, {
        issue: dastIssue,
        issueIndex: 1,
        modalTargetId: '#modal-mrwidget-issue',
      });

      expect(vm.$el.textContent.trim()).toContain(dastIssue.priority);
    });
  });

  describe('without priority', () => {
    it('does not rendere priority key', () => {
      const issueCopy = Object.assign({}, dastIssue);
      delete issueCopy.priority;

      vm = mountComponent(Component, {
        issue: issueCopy,
        issueIndex: 1,
        modalTargetId: '#modal-mrwidget-issue',
      });

      expect(vm.$el.textContent.trim()).not.toContain(dastIssue.priority);
    });
  });

  describe('issue name', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        issue: dastIssue,
        issueIndex: 1,
        modalTargetId: '#modal-mrwidget-issue',
      });
    });

    it('renders button with issue name', () => {
      expect(vm.$el.textContent.trim()).toContain(dastIssue.name);
    });
  });
});
