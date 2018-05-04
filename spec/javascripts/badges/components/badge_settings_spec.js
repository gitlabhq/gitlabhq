import $ from 'jquery';
import Vue from 'vue';
import store from '~/badges/store';
import BadgeSettings from '~/badges/components/badge_settings.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createDummyBadge } from '../dummy_badge';

describe('BadgeSettings component', () => {
  const Component = Vue.extend(BadgeSettings);
  let vm;

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-element"></div>
      <button
        id="dummy-modal-button"
        type="button"
        data-toggle="modal"
        data-target="#delete-badge-modal"
      >Show modal</button>
    `);
    vm = mountComponentWithStore(Component, {
      el: '#dummy-element',
      store,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('displays modal if button is clicked', done => {
    const badge = createDummyBadge();
    store.state.badgeInModal = badge;
    const modal = vm.$el.querySelector('#delete-badge-modal');
    const button = document.getElementById('dummy-modal-button');

    $(modal).on('shown.bs.modal', () => {
      expect(modal).toContainText('Delete badge?');
      const badgeElement = modal.querySelector('img.project-badge');
      expect(badgeElement).not.toBe(null);
      expect(badgeElement.getAttribute('src')).toBe(badge.renderedImageUrl);

      done();
    });

    Vue.nextTick()
      .then(() => {
        button.click();
      })
      .catch(done.fail);
  });

  it('displays a form to add a badge', () => {
    const form = vm.$el.querySelector('form:nth-of-type(2)');
    expect(form).not.toBe(null);
    const button = form.querySelector('.btn-success');
    expect(button).not.toBe(null);
    expect(button).toHaveText(/Add badge/);
  });

  it('displays badge list', () => {
    const badgeListElement = vm.$el.querySelector('.panel');
    expect(badgeListElement).not.toBe(null);
    expect(badgeListElement).toBeVisible();
    expect(badgeListElement).toContainText('Your badges');
  });

  describe('when editing', () => {
    beforeEach(done => {
      store.state.isEditing = true;

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('displays a form to edit a badge', () => {
      const form = vm.$el.querySelector('form:nth-of-type(1)');
      expect(form).not.toBe(null);
      const submitButton = form.querySelector('.btn-success');
      expect(submitButton).not.toBe(null);
      expect(submitButton).toHaveText(/Save changes/);
      const cancelButton = form.querySelector('.btn-cancel');
      expect(cancelButton).not.toBe(null);
      expect(cancelButton).toHaveText(/Cancel/);
    });

    it('displays no badge list', () => {
      const badgeListElement = vm.$el.querySelector('.panel');
      expect(badgeListElement).toBeHidden();
    });
  });

  describe('methods', () => {
    describe('onSubmitModal', () => {
      it('triggers ', () => {
        spyOn(vm, 'deleteBadge').and.callFake(() => Promise.resolve());
        const modal = vm.$el.querySelector('#delete-badge-modal');
        const deleteButton = modal.querySelector('.btn-danger');

        deleteButton.click();

        const badge = store.state.badgeInModal;
        expect(vm.deleteBadge).toHaveBeenCalledWith(badge);
      });
    });
  });
});
