import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { DUMMY_IMAGE_URL, TEST_HOST } from 'spec/test_constants';
import Badge from '~/badges/components/badge.vue';

describe('Badge component', () => {
  const Component = Vue.extend(Badge);
  const dummyProps = {
    imageUrl: DUMMY_IMAGE_URL,
    linkUrl: `${TEST_HOST}/badge/link/url`,
  };
  let vm;

  const findElements = () => {
    const buttons = vm.$el.querySelectorAll('button');
    return {
      badgeImage: vm.$el.querySelector('img.project-badge'),
      loadingIcon: vm.$el.querySelector('.gl-spinner'),
      reloadButton: buttons[buttons.length - 1],
    };
  };

  const createComponent = (props, el = null) => {
    vm = mountComponent(Component, props, el);
    const { badgeImage } = findElements();
    return new Promise(resolve => badgeImage.addEventListener('load', resolve)).then(() =>
      Vue.nextTick(),
    );
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('watchers', () => {
    describe('imageUrl', () => {
      it('sets isLoading and resets numRetries and hasError', done => {
        const props = { ...dummyProps };
        createComponent(props)
          .then(() => {
            expect(vm.isLoading).toBe(false);
            vm.hasError = true;
            vm.numRetries = 42;

            vm.imageUrl = `${props.imageUrl}#something/else`;

            return Vue.nextTick();
          })
          .then(() => {
            expect(vm.isLoading).toBe(true);
            expect(vm.numRetries).toBe(0);
            expect(vm.hasError).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('methods', () => {
    beforeEach(done => {
      createComponent({ ...dummyProps })
        .then(done)
        .catch(done.fail);
    });

    it('onError resets isLoading and sets hasError', () => {
      vm.hasError = false;
      vm.isLoading = true;

      vm.onError();

      expect(vm.hasError).toBe(true);
      expect(vm.isLoading).toBe(false);
    });

    it('onLoad sets isLoading', () => {
      vm.isLoading = true;

      vm.onLoad();

      expect(vm.isLoading).toBe(false);
    });

    it('reloadImage resets isLoading and hasError and increases numRetries', () => {
      vm.hasError = true;
      vm.isLoading = false;
      vm.numRetries = 0;

      vm.reloadImage();

      expect(vm.hasError).toBe(false);
      expect(vm.isLoading).toBe(true);
      expect(vm.numRetries).toBe(1);
    });
  });

  describe('behavior', () => {
    beforeEach(done => {
      setFixtures('<div id="dummy-element"></div>');
      createComponent({ ...dummyProps }, '#dummy-element')
        .then(done)
        .catch(done.fail);
    });

    it('shows a badge image after loading', () => {
      expect(vm.isLoading).toBe(false);
      expect(vm.hasError).toBe(false);
      const { badgeImage, loadingIcon, reloadButton } = findElements();

      expect(badgeImage).toBeVisible();
      expect(loadingIcon).toBeHidden();
      expect(reloadButton).toBeHidden();
      expect(vm.$el.innerText).toBe('');
    });

    it('shows a loading icon when loading', done => {
      vm.isLoading = true;

      Vue.nextTick()
        .then(() => {
          const { badgeImage, loadingIcon, reloadButton } = findElements();

          expect(badgeImage).toBeHidden();
          expect(loadingIcon).toBeVisible();
          expect(reloadButton).toBeHidden();
          expect(vm.$el.innerText).toBe('');
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows an error and reload button if loading failed', done => {
      vm.hasError = true;

      Vue.nextTick()
        .then(() => {
          const { badgeImage, loadingIcon, reloadButton } = findElements();

          expect(badgeImage).toBeHidden();
          expect(loadingIcon).toBeHidden();
          expect(reloadButton).toBeVisible();
          expect(reloadButton).toHaveSpriteIcon('retry');
          expect(vm.$el.innerText.trim()).toBe('No badge image');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
