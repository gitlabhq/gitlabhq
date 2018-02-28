import Vue from 'vue';
import modal from 'ee/vue_shared/security_reports/components/dast_modal.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('mr widget modal', () => {
  let vm;
  let Modal;

  beforeEach(() => {
    Modal = Vue.extend(modal);
    vm = mountComponent(Modal, {
      title: 'Title',
      targetId: 'targetId',
      instances: [{
        uri: 'uri',
        method: 'GET',
        evidence: 'evidence',
      }],
      description: 'Description!',
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a title', () => {
    expect(vm.$el.querySelector('.modal-title').textContent.trim()).toEqual('Title');
  });

  it('renders the target id', () => {
    expect(vm.$el.getAttribute('id')).toEqual('targetId');
  });

  it('renders the description', () => {
    expect(vm.$el.querySelector('.modal-body').textContent).toContain('Description!');
  });

  it('renders list of instances', () => {
    const instance = vm.$el.querySelector('.modal-body li').textContent;
    expect(instance).toContain('uri');
    expect(instance).toContain('GET');
    expect(instance).toContain('evidence');
  });
});
