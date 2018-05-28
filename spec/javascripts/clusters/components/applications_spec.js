import Vue from 'vue';
import applications from '~/clusters/components/applications.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

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
          jupyter: { title: 'JupyterHub' },
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

    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).toBeDefined();
    });

    it('renders a row for Jupyter', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-jupyter')).not.toBe(null);
    });
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
                externalIp: '0.0.0.0',
              },
              helm: { title: 'Helm Tiller' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '' },
            },
          });

          expect(vm.$el.querySelector('.js-ip-address').value).toEqual('0.0.0.0');

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
              jupyter: { title: 'JupyterHub', hostname: '' },
            },
          });

          expect(vm.$el.querySelector('.js-ip-address').value).toEqual('?');

          expect(vm.$el.querySelector('.js-no-ip-message')).not.toBe(null);
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
            jupyter: { title: 'JupyterHub', hostname: '' },
          },
        });

        expect(vm.$el.textContent).not.toContain('Ingress IP Address');
        expect(vm.$el.querySelector('.js-ip-address')).toBe(null);
      });
    });

    describe('Jupyter application', () => {
      describe('with ingress installed with ip & jupyter installable', () => {
        it('renders hostname active input', () => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller', status: 'installed' },
              ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '', status: 'installable' },
            },
          });

          expect(vm.$el.querySelector('.js-hostname').getAttribute('readonly')).toEqual(null);
        });
      });

      describe('with ingress installed without external ip', () => {
        it('does not render hostname input', () => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller', status: 'installed' },
              ingress: { title: 'Ingress', status: 'installed' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '', status: 'installable' },
            },
          });

          expect(vm.$el.querySelector('.js-hostname')).toBe(null);
        });
      });

      describe('with ingress & jupyter installed', () => {
        it('renders readonly input', () => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller', status: 'installed' },
              ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', status: 'installed', hostname: '' },
            },
          });

          expect(vm.$el.querySelector('.js-hostname').getAttribute('readonly')).toEqual('readonly');
        });
      });

      describe('without ingress installed', () => {
        beforeEach(() => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller' },
              ingress: { title: 'Ingress' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', status: 'not_installable' },
            },
          });
        });

        it('does not render input', () => {
          expect(vm.$el.querySelector('.js-hostname')).toBe(null);
        });

        it('renders disabled install button', () => {
          expect(
            vm.$el
              .querySelector(
                '.js-cluster-application-row-jupyter .js-cluster-application-install-button',
              )
              .getAttribute('disabled'),
          ).toEqual('disabled');
        });
      });
    });
  });
});
