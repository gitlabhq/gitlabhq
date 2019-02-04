import Vue from 'vue';
import applications from '~/clusters/components/applications.vue';
import { CLUSTER_TYPE } from '~/clusters/constants';
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

  describe('Project cluster applications', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        type: CLUSTER_TYPE.PROJECT,
        applications: {
          helm: { title: 'Helm Tiller' },
          ingress: { title: 'Ingress' },
          cert_manager: { title: 'Cert-Manager' },
          runner: { title: 'GitLab Runner' },
          prometheus: { title: 'Prometheus' },
          jupyter: { title: 'JupyterHub' },
          knative: { title: 'Knative' },
        },
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).not.toBeNull();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).not.toBeNull();
    });

    it('renders a row for Cert-Manager', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-cert_manager')).not.toBeNull();
    });

    it('renders a row for Prometheus', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-prometheus')).not.toBeNull();
    });

    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).not.toBeNull();
    });

    it('renders a row for Jupyter', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-jupyter')).not.toBeNull();
    });

    it('renders a row for Knative', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-knative')).not.toBeNull();
    });
  });

  describe('Group cluster applications', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        type: CLUSTER_TYPE.GROUP,
        applications: {
          helm: { title: 'Helm Tiller' },
          ingress: { title: 'Ingress' },
          cert_manager: { title: 'Cert-Manager' },
          runner: { title: 'GitLab Runner' },
          prometheus: { title: 'Prometheus' },
          jupyter: { title: 'JupyterHub' },
          knative: { title: 'Knative' },
        },
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).not.toBeNull();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).not.toBeNull();
    });

    it('renders a row for Cert-Manager', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-cert_manager')).not.toBeNull();
    });

    it('renders a row for Prometheus', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-prometheus')).toBeNull();
    });

    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).toBeNull();
    });

    it('renders a row for Jupyter', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-jupyter')).toBeNull();
    });

    it('renders a row for Knative', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-knative')).toBeNull();
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
              cert_manager: { title: 'Cert-Manager' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '' },
              knative: { title: 'Knative', hostname: '' },
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
              cert_manager: { title: 'Cert-Manager' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '' },
              knative: { title: 'Knative', hostname: '' },
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
            cert_manager: { title: 'Cert-Manager' },
            runner: { title: 'GitLab Runner' },
            prometheus: { title: 'Prometheus' },
            jupyter: { title: 'JupyterHub', hostname: '' },
            knative: { title: 'Knative', hostname: '' },
          },
        });

        expect(vm.$el.textContent).not.toContain('Ingress IP Address');
        expect(vm.$el.querySelector('.js-ip-address')).toBe(null);
      });
    });

    describe('Cert-Manager application', () => {
      describe('when not installed', () => {
        it('renders email & allows editing', () => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller', status: 'installed' },
              ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
              cert_manager: {
                title: 'Cert-Manager',
                email: 'before@example.com',
                status: 'installable',
              },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '', status: 'installable' },
              knative: { title: 'Knative', hostname: '', status: 'installable' },
            },
          });

          expect(vm.$el.querySelector('.js-email').value).toEqual('before@example.com');
          expect(vm.$el.querySelector('.js-email').getAttribute('readonly')).toBe(null);
        });
      });

      describe('when installed', () => {
        it('renders email in readonly', () => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller', status: 'installed' },
              ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
              cert_manager: {
                title: 'Cert-Manager',
                email: 'after@example.com',
                status: 'installed',
              },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '', status: 'installable' },
              knative: { title: 'Knative', hostname: '', status: 'installable' },
            },
          });

          expect(vm.$el.querySelector('.js-email').value).toEqual('after@example.com');
          expect(vm.$el.querySelector('.js-email').getAttribute('readonly')).toEqual('readonly');
        });
      });
    });

    describe('Jupyter application', () => {
      describe('with ingress installed with ip & jupyter installable', () => {
        it('renders hostname active input', () => {
          vm = mountComponent(Applications, {
            applications: {
              helm: { title: 'Helm Tiller', status: 'installed' },
              ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
              cert_manager: { title: 'Cert-Manager' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '', status: 'installable' },
              knative: { title: 'Knative', hostname: '', status: 'installable' },
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
              cert_manager: { title: 'Cert-Manager' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '', status: 'installable' },
              knative: { title: 'Knative', hostname: '', status: 'installable' },
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
              cert_manager: { title: 'Cert-Manager' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', status: 'installed', hostname: '' },
              knative: { title: 'Knative', status: 'installed', hostname: '' },
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
              cert_manager: { title: 'Cert-Manager' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', status: 'not_installable' },
              knative: { title: 'Knative' },
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
