import $ from 'jquery';
import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import store from '~/ide/stores';
import NavDropdown from '~/ide/components/nav_dropdown.vue';
import { PERMISSION_READ_MR } from '~/ide/constants';

const TEST_PROJECT_ID = 'lorem-ipsum';

describe('IDE NavDropdown', () => {
  const Component = Vue.extend(NavDropdown);
  let vm;
  let $dropdown;

  beforeEach(() => {
    store.state.currentProjectId = TEST_PROJECT_ID;
    Vue.set(store.state.projects, TEST_PROJECT_ID, {
      userPermissions: {
        [PERMISSION_READ_MR]: true,
      },
    });
    vm = mountComponentWithStore(Component, { store });
    $dropdown = $(vm.$el);

    // block dispatch from doing anything
    spyOn(vm.$store, 'dispatch');
  });

  afterEach(() => {
    vm.$destroy();
  });

  const findIcon = name => vm.$el.querySelector(`.ic-${name}`);
  const findMRIcon = () => findIcon('merge-request');

  it('renders nothing initially', () => {
    expect(vm.$el).not.toContainElement('.ide-nav-form');
  });

  it('renders nav form when show.bs.dropdown', done => {
    $dropdown.trigger('show.bs.dropdown');

    vm.$nextTick()
      .then(() => {
        expect(vm.$el).toContainElement('.ide-nav-form');
      })
      .then(done)
      .catch(done.fail);
  });

  it('destroys nav form when closed', done => {
    $dropdown.trigger('show.bs.dropdown');
    $dropdown.trigger('hide.bs.dropdown');

    vm.$nextTick()
      .then(() => {
        expect(vm.$el).not.toContainElement('.ide-nav-form');
      })
      .then(done)
      .catch(done.fail);
  });

  it('renders merge request icon', () => {
    expect(findMRIcon()).not.toBeNull();
  });

  describe('when user cannot read merge requests', () => {
    beforeEach(done => {
      store.state.projects[TEST_PROJECT_ID].userPermissions = {};

      vm.$nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('does not render merge requests', () => {
      expect(findMRIcon()).toBeNull();
    });
  });
});
