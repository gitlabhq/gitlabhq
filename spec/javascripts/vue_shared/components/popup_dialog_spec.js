import Vue from 'vue';
import PopupDialog from '~/vue_shared/components/popup_dialog.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('PopupDialog', () => {
  it('does not render a primary button if no primaryButtonLabel', () => {
    const popupDialog = Vue.extend(PopupDialog);
    const vm = mountComponent(popupDialog);

    expect(vm.$el.querySelector('.js-primary-button')).toBeNull();
  });
});
