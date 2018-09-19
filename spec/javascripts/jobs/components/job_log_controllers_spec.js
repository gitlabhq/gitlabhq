import Vue from 'vue';
import component from '~/jobs/components/job_log_controllers.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Job log controllers', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('Truncate information', () => {

    beforeEach(() => {
      vm = mountComponent(Component, {
        rawTracePath: '/raw',
        canEraseJob: true,
        size: 511952,
        canScrollToTop: true,
        canScrollToBottom: true,
      });
    });

    it('renders size information', () => {
      expect(vm.$el.querySelector('.js-truncated-info').textContent).toContain('499.95 KiB');
    });

    it('renders link to raw trace', () => {
      expect(vm.$el.querySelector('.js-raw-link').getAttribute('href')).toEqual('/raw');
    });

  });

  describe('links section', () => {
    describe('with raw trace path', () => {
      it('renders raw trace link', () => {
        vm = mountComponent(Component, {
          rawTracePath: '/raw',
          canEraseJob: true,
          size: 511952,
          canScrollToTop: true,
          canScrollToBottom: true,
        });

        expect(vm.$el.querySelector('.js-raw-link-controller').getAttribute('href')).toEqual('/raw');
      });
    });

    describe('without raw trace path', () => {
      it('does not render raw trace link', () => {
        vm = mountComponent(Component, {
          canEraseJob: true,
          size: 511952,
          canScrollToTop: true,
          canScrollToBottom: true,
        });

        expect(vm.$el.querySelector('.js-raw-link-controller')).toBeNull();
      });
    });

    describe('when is erasable', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          rawTracePath: '/raw',
          canEraseJob: true,
          size: 511952,
          canScrollToTop: true,
          canScrollToBottom: true,
        });
      });

      it('renders erase job button', () => {
        expect(vm.$el.querySelector('.js-erase-link')).not.toBeNull();
      });

      describe('on click', () => {
        describe('when user confirms action', () => {
          it('emits eraseJob event', () => {
            spyOn(window, 'confirm').and.returnValue(true);
            spyOn(vm, '$emit');

            vm.$el.querySelector('.js-erase-link').click();

            expect(vm.$emit).toHaveBeenCalledWith('eraseJob');
          });
        });

        describe('when user does not confirm action', () => {
          it('does not emit eraseJob event', () => {
            spyOn(window, 'confirm').and.returnValue(false);
            spyOn(vm, '$emit');

            vm.$el.querySelector('.js-erase-link').click();

            expect(vm.$emit).not.toHaveBeenCalledWith('eraseJob');
          });
        });
      });
    });

    describe('when it is not erasable', () => {
      it('does not render erase button', () => {
        vm = mountComponent(Component, {
          rawTracePath: '/raw',
          canEraseJob: false,
          size: 511952,
          canScrollToTop: true,
          canScrollToBottom: true,
        });

        expect(vm.$el.querySelector('.js-erase-link')).toBeNull();
      });
    });
  });

  describe('scroll buttons', () => {
    describe('scroll top button', () => {
      describe('when user can scroll top', () => {
        beforeEach(() => {
          vm = mountComponent(Component, {
            rawTracePath: '/raw',
            canEraseJob: true,
            size: 511952,
            canScrollToTop: true,
            canScrollToBottom: true,
          });
        });

        it('renders enabled scroll top button', () => {
          expect(vm.$el.querySelector('.js-scroll-top').getAttribute('disabled')).toBeNull();
        });

        it('emits scrollJobLogTop event on click', () => {
          spyOn(vm, '$emit');
          vm.$el.querySelector('.js-scroll-top').click();

          expect(vm.$emit).toHaveBeenCalledWith('scrollJobLogTop');
        });
      });

      describe('when user can not scroll top', () => {
        beforeEach(() => {
          vm = mountComponent(Component, {
            rawTracePath: '/raw',
            canEraseJob: true,
            size: 511952,
            canScrollToTop: false,
            canScrollToBottom: true,
          });
        });

        it('renders disabled scroll top button', () => {
          expect(vm.$el.querySelector('.js-scroll-top').getAttribute('disabled')).toEqual('disabled');
        });

        it('does not emit scrollJobLogTop event on click', () => {
          spyOn(vm, '$emit');
          vm.$el.querySelector('.js-scroll-top').click();

          expect(vm.$emit).not.toHaveBeenCalledWith('scrollJobLogTop');
        });
      });
    });

    describe('scroll bottom button', () => {
      describe('when user can scroll bottom', () => {
        beforeEach(() => {
          vm = mountComponent(Component, {
            rawTracePath: '/raw',
            canEraseJob: true,
            size: 511952,
            canScrollToTop: true,
            canScrollToBottom: true,
          });
        });

        it('renders enabled scroll bottom button', () => {
          expect(vm.$el.querySelector('.js-scroll-bottom').getAttribute('disabled')).toBeNull();
        });

        it('emits scrollJobLogBottom event on click', () => {
          spyOn(vm, '$emit');
          vm.$el.querySelector('.js-scroll-bottom').click();

          expect(vm.$emit).toHaveBeenCalledWith('scrollJobLogBottom');
        });
      });

      describe('when user can not scroll bottom', () => {
        beforeEach(() => {
          vm = mountComponent(Component, {
            rawTracePath: '/raw',
            canEraseJob: true,
            size: 511952,
            canScrollToTop: true,
            canScrollToBottom: false,
          });
        });

        it('renders disabled scroll bottom button', () => {
          expect(vm.$el.querySelector('.js-scroll-bottom').getAttribute('disabled')).toEqual('disabled');

        });

        it('does not emit scrollJobLogBottom event on click', () => {
          spyOn(vm, '$emit');
          vm.$el.querySelector('.js-scroll-bottom').click();

          expect(vm.$emit).not.toHaveBeenCalledWith('scrollJobLogBottom');
        });
      });
    });
  });
});

