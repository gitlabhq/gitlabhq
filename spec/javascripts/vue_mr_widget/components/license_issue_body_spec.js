import Vue from 'vue';

import LicenseIssueBody from 'ee/vue_merge_request_widget/components/license_issue_body.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { licenseReport } from '../mock_data';

const licenseReportIssue = licenseReport[0];

const createComponent = (issue = licenseReportIssue) => {
  const Component = Vue.extend(LicenseIssueBody);

  return mountComponent(Component, { issue });
};

describe('LicenseIssueBody', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('remainingPackages', () => {
      it('returns string with count of issue.packages when it exceeds `displayPackageCount` prop', () => {
        expect(vm.remainingPackages).toBe('2 more');
      });

      it('returns empty string when count of issue.packages does not exceed `displayPackageCount` prop', (done) => {
        vm.displayPackageCount = licenseReportIssue.packages.length + 1;
        Vue.nextTick()
          .then(() => {
            expect(vm.remainingPackages).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('methods', () => {
    describe('getPackagesString', () => {
      it('returns string containing name of package when issue.packages contains only one item', (done) => {
        vm.issue = Object.assign({}, licenseReportIssue, {
          // We need only 3 elements as it is same as
          // default value of `displayPackageCount`
          // which is 3.
          packages: licenseReportIssue.packages.slice(0, 1),
        });
        Vue.nextTick()
          .then(() => {
            expect(vm.getPackagesString(true)).toBe('pg');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns string with comma separated names of packages up to 3 when `truncate` param is true and issue.packages count exceeds `displayPackageCount`', () => {
        expect(vm.getPackagesString(true)).toBe('pg, puma, foo and ');
      });

      it('returns string with comma separated names of all the packages when `truncate` param is true and issue.packages count does NOT exceed `displayPackageCount`', (done) => {
        vm.issue = Object.assign({}, licenseReportIssue, {
          // We need only 3 elements as it is same as
          // default value of `displayPackageCount`
          // which is 3.
          packages: licenseReportIssue.packages.slice(0, 3),
        });
        Vue.nextTick()
          .then(() => {
            expect(vm.getPackagesString(true)).toBe('pg, puma and foo');
          })
          .then(done)
          .catch(done.fail);
      });

      it('returns string with comma separated names of all the packages when `truncate` param is false irrespective of issue.packages count', () => {
        expect(vm.getPackagesString(false)).toBe('pg, puma, foo, bar and baz');
      });
    });

    describe('handleShowPackages', () => {
      it('sets value of `showAllPackages` prop to true', () => {
        vm.showAllPackages = false;
        vm.handleShowPackages();
        expect(vm.showAllPackages).toBe(true);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `license-item`', () => {
      expect(vm.$el.classList.contains('license-item')).toBe(true);
    });

    it('renders license link element', () => {
      const linkEl = vm.$el.querySelector('a');
      expect(linkEl).not.toBeNull();
      expect(linkEl.getAttribute('href')).toBe(licenseReportIssue.url);
      expect(linkEl.innerText.trim()).toBe(licenseReportIssue.name);
    });

    it('renders packages list for a particular license', () => {
      const packagesEl = vm.$el.querySelector('.license-dependencies');
      expect(packagesEl).not.toBeNull();
      expect(packagesEl.innerText.trim()).toBe('pg, puma, foo and');
    });

    it('renders more packages button element', () => {
      const buttonEl = vm.$el.querySelector('.btn-show-all-packages');
      expect(buttonEl).not.toBeNull();
      expect(buttonEl.innerText.trim()).toBe('2 more');
    });
  });
});
