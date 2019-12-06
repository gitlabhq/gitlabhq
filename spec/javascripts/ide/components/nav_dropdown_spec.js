import $ from 'jquery';
import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import store from '~/ide/stores';
import NavDropdown from '~/ide/components/nav_dropdown.vue';

describe('IDE NavDropdown', () => {
  const Component = Vue.extend(NavDropdown);
  let vm;
  let $dropdown;

  beforeEach(() => {
    vm = mountComponentWithStore(Component, { store });
    $dropdown = $(vm.$el);

    // block dispatch from doing anything
    spyOn(vm.$store, 'dispatch');
  });

  afterEach(() => {
    vm.$destroy();
  });

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
});
