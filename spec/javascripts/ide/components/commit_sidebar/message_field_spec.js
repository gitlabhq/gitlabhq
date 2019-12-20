import Vue from 'vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';
import CommitMessageField from '~/ide/components/commit_sidebar/message_field.vue';

describe('IDE commit message field', () => {
  const Component = Vue.extend(CommitMessageField);
  let vm;

  beforeEach(() => {
    setFixtures('<div id="app"></div>');

    vm = createComponent(
      Component,
      {
        text: '',
        placeholder: 'testing',
      },
      '#app',
    );
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('adds is-focused class on focus', done => {
    vm.$el.querySelector('textarea').focus();

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.is-focused')).not.toBeNull();

      done();
    });
  });

  it('removed is-focused class on blur', done => {
    vm.$el.querySelector('textarea').focus();

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.is-focused')).not.toBeNull();

        vm.$el.querySelector('textarea').blur();

        return vm.$nextTick();
      })
      .then(() => {
        expect(vm.$el.querySelector('.is-focused')).toBeNull();

        done();
      })
      .then(done)
      .catch(done.fail);
  });

  it('emits input event on input', () => {
    spyOn(vm, '$emit');

    const textarea = vm.$el.querySelector('textarea');
    textarea.value = 'testing';

    textarea.dispatchEvent(new Event('input'));

    expect(vm.$emit).toHaveBeenCalledWith('input', 'testing');
  });

  describe('highlights', () => {
    describe('subject line', () => {
      it('does not highlight less than 50 characters', done => {
        vm.text = 'text less than 50 chars';

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.highlights span').textContent).toContain(
              'text less than 50 chars',
            );

            expect(vm.$el.querySelector('mark').style.display).toBe('none');
          })
          .then(done)
          .catch(done.fail);
      });

      it('highlights characters over 50 length', done => {
        vm.text =
          'text less than 50 chars that should not highlighted. text more than 50 should be highlighted';

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.highlights span').textContent).toContain(
              'text less than 50 chars that should not highlighte',
            );

            expect(vm.$el.querySelector('mark').style.display).not.toBe('none');
            expect(vm.$el.querySelector('mark').textContent).toBe(
              'd. text more than 50 should be highlighted',
            );
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('body text', () => {
      it('does not highlight body text less tan 72 characters', done => {
        vm.text = 'subject line\nbody content';

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelectorAll('.highlights span').length).toBe(2);
            expect(vm.$el.querySelectorAll('mark')[1].style.display).toBe('none');
          })
          .then(done)
          .catch(done.fail);
      });

      it('highlights body text more than 72 characters', done => {
        vm.text =
          'subject line\nbody content that will be highlighted when it is more than 72 characters in length';

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelectorAll('.highlights span').length).toBe(2);
            expect(vm.$el.querySelectorAll('mark')[1].style.display).not.toBe('none');
            expect(vm.$el.querySelectorAll('mark')[1].textContent).toBe(' in length');
          })
          .then(done)
          .catch(done.fail);
      });

      it('highlights body text & subject line', done => {
        vm.text =
          'text less than 50 chars that should not highlighted\nbody content that will be highlighted when it is more than 72 characters in length';

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelectorAll('.highlights span').length).toBe(2);
            expect(vm.$el.querySelectorAll('mark').length).toBe(2);

            expect(vm.$el.querySelectorAll('mark')[0].textContent).toContain('d');
            expect(vm.$el.querySelectorAll('mark')[1].textContent).toBe(' in length');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('scrolling textarea', () => {
    it('updates transform of highlights', done => {
      vm.text = 'subject line\n\n\n\n\n\n\n\n\n\n\nbody content';

      vm.$nextTick()
        .then(() => {
          vm.$el.querySelector('textarea').scrollTo(0, 50);

          vm.handleScroll();
        })
        .then(vm.$nextTick)
        .then(() => {
          expect(vm.scrollTop).toBe(50);
          expect(vm.$el.querySelector('.highlights').style.transform).toBe(
            'translate3d(0px, -50px, 0px)',
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
