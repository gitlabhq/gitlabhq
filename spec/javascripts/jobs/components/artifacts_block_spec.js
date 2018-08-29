import Vue from 'vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import component from '~/jobs/components/artifacts_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Artifacts block', () => {
  const Component = Vue.extend(component);
  let vm;

  const expireAt = '2018-08-14T09:38:49.157Z';
  const timeago = getTimeago();
  const formatedDate = timeago.format(expireAt);

  afterEach(() => {
    vm.$destroy();
  });

  describe('with expired artifacts', () => {
    it('renders expired artifact date and info', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
      });

      expect(vm.$el.querySelector('.js-artifacts-removed')).not.toBeNull();
      expect(vm.$el.querySelector('.js-artifacts-will-be-removed')).toBeNull();
      expect(vm.$el.textContent).toContain(formatedDate);
    });
  });

  describe('with artifacts that will expire', () => {
    it('renders will expire artifact date and info', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: false,
        willArtifactsExpire: true,
        expireAt,
      });

      expect(vm.$el.querySelector('.js-artifacts-removed')).toBeNull();
      expect(vm.$el.querySelector('.js-artifacts-will-be-removed')).not.toBeNull();
      expect(vm.$el.textContent).toContain(formatedDate);
    });
  });

  describe('when the user can keep the artifacts', () => {
    it('renders the keep button', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
        keepArtifactsPath: '/keep',
      });

      expect(vm.$el.querySelector('.js-keep-artifacts')).not.toBeNull();
    });
  });

  describe('when the user can not keep the artifacts', () => {
    it('does not render the keep button', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
      });

      expect(vm.$el.querySelector('.js-keep-artifacts')).toBeNull();
    });
  });

  describe('when the user can download the artifacts', () => {
    it('renders the download button', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
        downloadArtifactsPath: '/download',
      });

      expect(vm.$el.querySelector('.js-download-artifacts')).not.toBeNull();
    });
  });

  describe('when the user can not download the artifacts', () => {
    it('does not render the keep button', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
      });

      expect(vm.$el.querySelector('.js-download-artifacts')).toBeNull();
    });
  });

  describe('when the user can browse the artifacts', () => {
    it('does not render the browse button', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
        browseArtifactsPath: '/browse',
      });

      expect(vm.$el.querySelector('.js-browse-artifacts')).not.toBeNull();
    });
  });

  describe('when the user can not browse the artifacts', () => {
    it('does not render the browse button', () => {
      vm = mountComponent(Component, {
        haveArtifactsExpired: true,
        willArtifactsExpire: false,
        expireAt,
      });

      expect(vm.$el.querySelector('.js-browse-artifacts')).toBeNull();
    });
  });
});
