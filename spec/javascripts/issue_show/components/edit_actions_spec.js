import Vue from 'vue';
import editActions from '~/issue_show/components/edit_actions.vue';
import eventHub from '~/issue_show/event_hub';

describe('Edit Actions components', () => {
  let vm;

  beforeEach((done) => {
    const Component = Vue.extend(editActions);

    spyOn(eventHub, '$emit');

    vm = new Component().$mount();

    Vue.nextTick(done);
  });

  it('renders all buttons as enabled', () => {
    expect(
      vm.$el.querySelectorAll('.disabled').length,
    ).toBe(0);

    expect(
      vm.$el.querySelectorAll('[disabled]').length,
    ).toBe(0);
  });

  describe('updateIssuable', () => {
    it('sends update.issauble event when clicking save button', () => {
      vm.$el.querySelector('.btn-save').click();

      expect(
        eventHub.$emit,
      ).toHaveBeenCalledWith('update.issuable');
    });

    it('shows loading icon after clicking save button', (done) => {
      vm.$el.querySelector('.btn-save').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.btn-save .fa'),
        ).not.toBeNull();

        done();
      });
    });

    it('disabled button after clicking save button', (done) => {
      vm.$el.querySelector('.btn-save').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.btn-save').getAttribute('disabled'),
        ).toBe('disabled');

        done();
      });
    });
  });

  describe('closeForm', () => {
    it('emits close.form when clicking cancel', () => {
      vm.$el.querySelector('.btn-default').click();

      expect(
        eventHub.$emit,
      ).toHaveBeenCalledWith('close.form');
    });
  });

  describe('deleteIssuable', () => {
    it('sends delete.issuable event when clicking save button', () => {
      spyOn(window, 'confirm').and.returnValue(true);
      vm.$el.querySelector('.btn-danger').click();

      expect(
        eventHub.$emit,
      ).toHaveBeenCalledWith('delete.issuable');
    });

    it('shows loading icon after clicking delete button', (done) => {
      spyOn(window, 'confirm').and.returnValue(true);
      vm.$el.querySelector('.btn-danger').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.btn-danger .fa'),
        ).not.toBeNull();

        done();
      });
    });

    it('does no actions when confirm is false', (done) => {
      spyOn(window, 'confirm').and.returnValue(false);
      vm.$el.querySelector('.btn-danger').click();

      Vue.nextTick(() => {
        expect(
          eventHub.$emit,
        ).not.toHaveBeenCalledWith('delete.issuable');
        expect(
          vm.$el.querySelector('.btn-danger .fa'),
        ).toBeNull();

        done();
      });
    });
  });
});
