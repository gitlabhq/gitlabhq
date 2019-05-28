import Vue from 'vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import component from '~/jobs/components/artifacts_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';
import { trimText } from '../../helpers/text_helper';

describe('Artifacts block', () => {
  const Component = Vue.extend(component);
  let vm;

  const expireAt = '2018-08-14T09:38:49.157Z';
  const timeago = getTimeago();
  const formattedDate = timeago.format(expireAt);

  const expiredArtifact = {
    expire_at: expireAt,
    expired: true,
  };

  const nonExpiredArtifact = {
    download_path: '/gitlab-org/gitlab-ce/-/jobs/98314558/artifacts/download',
    browse_path: '/gitlab-org/gitlab-ce/-/jobs/98314558/artifacts/browse',
    keep_path: '/gitlab-org/gitlab-ce/-/jobs/98314558/artifacts/keep',
    expire_at: expireAt,
    expired: false,
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('with expired artifacts', () => {
    it('renders expired artifact date and info', () => {
      vm = mountComponent(Component, {
        artifact: expiredArtifact,
      });

      expect(vm.$el.querySelector('.js-artifacts-removed')).not.toBeNull();
      expect(vm.$el.querySelector('.js-artifacts-will-be-removed')).toBeNull();
      expect(trimText(vm.$el.querySelector('.js-artifacts-removed').textContent)).toEqual(
        `The artifacts were removed ${formattedDate}`,
      );
    });
  });

  describe('with artifacts that will expire', () => {
    it('renders will expire artifact date and info', () => {
      vm = mountComponent(Component, {
        artifact: nonExpiredArtifact,
      });

      expect(vm.$el.querySelector('.js-artifacts-removed')).toBeNull();
      expect(vm.$el.querySelector('.js-artifacts-will-be-removed')).not.toBeNull();
      expect(trimText(vm.$el.querySelector('.js-artifacts-will-be-removed').textContent)).toEqual(
        `The artifacts will be removed ${formattedDate}`,
      );
    });
  });

  describe('with keep path', () => {
    it('renders the keep button', () => {
      vm = mountComponent(Component, {
        artifact: nonExpiredArtifact,
      });

      expect(vm.$el.querySelector('.js-keep-artifacts')).not.toBeNull();
    });
  });

  describe('without keep path', () => {
    it('does not render the keep button', () => {
      vm = mountComponent(Component, {
        artifact: expiredArtifact,
      });

      expect(vm.$el.querySelector('.js-keep-artifacts')).toBeNull();
    });
  });

  describe('with download path', () => {
    it('renders the download button', () => {
      vm = mountComponent(Component, {
        artifact: nonExpiredArtifact,
      });

      expect(vm.$el.querySelector('.js-download-artifacts')).not.toBeNull();
    });
  });

  describe('without download path', () => {
    it('does not render the keep button', () => {
      vm = mountComponent(Component, {
        artifact: expiredArtifact,
      });

      expect(vm.$el.querySelector('.js-download-artifacts')).toBeNull();
    });
  });

  describe('with browse path', () => {
    it('does not render the browse button', () => {
      vm = mountComponent(Component, {
        artifact: nonExpiredArtifact,
      });

      expect(vm.$el.querySelector('.js-browse-artifacts')).not.toBeNull();
    });
  });

  describe('without browse path', () => {
    it('does not render the browse button', () => {
      vm = mountComponent(Component, {
        artifact: expiredArtifact,
      });

      expect(vm.$el.querySelector('.js-browse-artifacts')).toBeNull();
    });
  });
});
