import Vue from 'vue';
import applications from '~/clusters/components/applications.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Applications', () => {
  let vm;
  let Applications;

  beforeEach(() => {
    Applications = Vue.extend(applications);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        applications: {
          helm: { title: 'Helm Tiller' },
          ingress: { title: 'Ingress' },
          runner: { title: 'GitLab Runner' },
          prometheus: { title: 'Prometheus' },
        },
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).toBeDefined();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).toBeDefined();
    });

    it('renders a row for Prometheus', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-prometheus')).toBeDefined();
    });

    /* * /
    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).toBeDefined();
    });
    /* */
  });

  describe('Ingress application', () => {
    describe('when installed', () => {
      describe('with ip address', () => {
        it('renders ip address with a clipboard button', () => {
          vm = mountComponent(Applications, {
            applications: {
              ingress: {
                title: 'Ingress',
                status: 'installed',
                external_ip: '0.0.0.0',
              },
              helm: { title: 'Helm Tiller' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
            },
          });

          expect(
            vm.$el.querySelector('#ipAddress').getAttribute('placeholder'),
          ).toEqual('0.0.0.0');
          expect(
            vm.$el.querySelector('.js-clipboard-btn').getAttribute('data-clipboard-text'),
          ).toEqual('0.0.0.0');
        });
      });

      describe('without ip address', () => {
        it('renders an input text with a question mark and an alert text', () => {
          vm = mountComponent(Applications, {
            applications: {
              ingress: {
                title: 'Ingress',
                status: 'installed',
              },
              helm: { title: 'Helm Tiller' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
            },
          });

          expect(
            vm.$el.querySelector('#ipAddress').getAttribute('placeholder'),
          ).toEqual('?');

          expect(
            vm.$el.querySelector('.js-no-ip-message').textContent.replace(/\n(\s)+/g, ' ').trim(),
          ).toEqual(
            'The IP address is in process to be assigned, please check your Kubernetes cluster or Quotas on GKE if it takes a long time. More information',
          );
        });
      });
    });

    describe('before installing', () => {
      it('does not render the IP address', () => {
        vm = mountComponent(Applications, {
          applications: {
            helm: { title: 'Helm Tiller' },
            ingress: { title: 'Ingress' },
            runner: { title: 'GitLab Runner' },
            prometheus: { title: 'Prometheus' },
          },
        });

        expect(vm.$el.textContent).not.toContain('Ingress IP Address');
        expect(vm.$el.querySelector('#ipAddress')).toBe(null);
      });
    });
  });
});
