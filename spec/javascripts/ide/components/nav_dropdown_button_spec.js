import Vue from 'vue';
import { trimText } from 'spec/helpers/text_helper';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import NavDropdownButton from '~/ide/components/nav_dropdown_button.vue';
import store from '~/ide/stores';
import { resetStore } from '../helpers';

describe('NavDropdown', () => {
  const TEST_BRANCH_ID = 'lorem-ipsum-dolar';
  const TEST_MR_ID = '12345';
  const Component = Vue.extend(NavDropdownButton);
  let vm;

  beforeEach(() => {
    vm = mountComponentWithStore(Component, { store });

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(store);
  });

  it('renders empty placeholders, if state is falsey', () => {
    expect(trimText(vm.$el.textContent)).toEqual('- -');
  });

  it('renders branch name, if state has currentBranchId', done => {
    vm.$store.state.currentBranchId = TEST_BRANCH_ID;

    vm.$nextTick()
      .then(() => {
        expect(trimText(vm.$el.textContent)).toEqual(`${TEST_BRANCH_ID} -`);
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders mr id, if state has currentMergeRequestId', done => {
    vm.$store.state.currentMergeRequestId = TEST_MR_ID;

    vm.$nextTick()
      .then(() => {
        expect(trimText(vm.$el.textContent)).toEqual(`- !${TEST_MR_ID}`);
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders branch and mr, if state has both', done => {
    vm.$store.state.currentBranchId = TEST_BRANCH_ID;
    vm.$store.state.currentMergeRequestId = TEST_MR_ID;

    vm.$nextTick()
      .then(() => {
        expect(trimText(vm.$el.textContent)).toEqual(`${TEST_BRANCH_ID} !${TEST_MR_ID}`);
      })
      .then(done)
      .catch(done.fail);
  });
});
