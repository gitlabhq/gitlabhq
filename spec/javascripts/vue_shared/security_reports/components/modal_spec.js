import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import createStore from 'ee/vue_shared/security_reports/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

describe('Security Reports modal', () => {
  const Component = Vue.extend(component);
  let vm;
  const store = createStore();

  beforeEach(() => {
    store.dispatch('setVulnerabilityFeedbackPath', 'path');
    store.dispatch('setVulnerabilityFeedbackHelpPath', 'feedbacksHelpPath');
    store.dispatch('setPipelineId', 123);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with dismissed issue', () => {
    beforeEach(() => {
      store.dispatch('setModalData', {
        tool: 'bundler_audit',
        message: 'Arbitrary file existence disclosure in Action Pack',
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
        cve: 'CVE-2014-9999',
        file: 'Gemfile.lock',
        solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
        title: 'Arbitrary file existence disclosure in Action Pack',
        path: 'Gemfile.lock',
        urlPath: 'path/Gemfile.lock',
        isDismissed: true,
        dismissalFeedback: {
          id: 1,
          category: 'sast',
          feedback_type: 'dismissal',
          issue_id: null,
          author: {
            name: 'John Smith',
            username: 'jsmith',
            web_url: 'https;//gitlab.com/user1',
          },
          pipeline: {
            id: 123,
            path: '/jsmith/awesome-project/pipelines/123',
          },
        },
      });

      vm = mountComponentWithStore(Component, {
        store,
      });
    });

    it('renders dismissal author and associated pipeline', () => {
      expect(vm.$el.textContent.trim()).toContain('@jsmith');
      expect(vm.$el.textContent.trim()).toContain('#123');
    });

    it('renders button to revert dismissal', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual(
        'Revert dismissal',
      );
    });

    it('calls revertDismissed when revert dismissal button is clicked', () => {
      spyOn(vm, 'revertDismissIssue');

      const button = vm.$el.querySelector('.js-dismiss-btn');
      button.click();

      expect(vm.revertDismissIssue).toHaveBeenCalled();
    });
  });

  describe('with not dismissed isssue', () => {
    beforeEach(() => {
      store.dispatch('setModalData', {
        tool: 'bundler_audit',
        message: 'Arbitrary file existence disclosure in Action Pack',
        url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
        cve: 'CVE-2014-9999',
        file: 'Gemfile.lock',
        solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
        title: 'Arbitrary file existence disclosure in Action Pack',
        path: 'Gemfile.lock',
        urlPath: 'path/Gemfile.lock',
      });

      vm = mountComponentWithStore(Component, {
        store,
      });
    });

    it('renders button to dismiss issue', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual(
        'Dismiss vulnerability',
      );
    });

    it('calls dismissIssue when dismiss issue button is clicked', () => {
      spyOn(vm, 'dismissIssue');

      const button = vm.$el.querySelector('.js-dismiss-btn');
      button.click();

      expect(vm.dismissIssue).toHaveBeenCalled();
    });
  });

  describe('with instances', () => {
    beforeEach(() => {
      store.dispatch('setModalData', {
        title: 'Absence of Anti-CSRF Tokens',
        riskcode: '1',
        riskdesc: 'Low (Medium)',
        desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
        pluginid: '123',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
            method: 'GET',
            evidence:
              "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
          },
          {
            uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
            method: 'GET',
            evidence:
              "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
          },
        ],
        description: ' No Anti-CSRF tokens were found in a HTML submission form. ',
        solution: '',
      });

      vm = mountComponentWithStore(Component, {
        store,
      });
    });

    it('renders instances list', () => {
      const instances = vm.$el.querySelectorAll('.report-block-list li');

      expect(instances[0].textContent).toContain(
        'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
      );
      expect(instances[1].textContent).toContain(
        'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
      );
    });
  });

  describe('data & create issue button', () => {
    beforeEach(() => {
      store.dispatch('setModalData', {
        tool: 'bundler_audit',
        message: 'Arbitrary file existence disclosure in Action Pack',
        cve: 'CVE-2014-9999',
        solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
        title: 'Arbitrary file existence disclosure in Action Pack',
        path: 'Gemfile.lock',
        urlPath: 'path/Gemfile.lock',
        location: {
          file: 'Gemfile.lock',
        },
        links: [{
          url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
        }],
      });

      vm = mountComponentWithStore(Component, {
        store,
      });
    });

    it('renders keys in `data`', () => {
      expect(vm.$el.textContent).toContain('Arbitrary file existence disclosure in Action Pack');
      expect(vm.$el.textContent).toContain(
        'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
      );
    });

    it('renders link fields with link', () => {
      expect(vm.$el.querySelector('.js-link-file').getAttribute('href')).toEqual('path/Gemfile.lock');
    });

    it('renders help link', () => {
      expect(vm.$el.querySelector('.js-link-vulnerabilityFeedbackHelpPath').getAttribute('href')).toEqual('feedbacksHelpPath');
    });
  });
});
