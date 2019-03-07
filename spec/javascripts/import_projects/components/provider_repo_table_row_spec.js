import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createStore from '~/import_projects/store';
import providerRepoTableRow from '~/import_projects/components/provider_repo_table_row.vue';
import STATUS_MAP, { STATUSES } from '~/import_projects/constants';
import setTimeoutPromise from '../../helpers/set_timeout_promise_helper';

describe('ProviderRepoTableRow', () => {
  let store;
  let vm;
  const repo = {
    id: 10,
    sanitizedName: 'sanitizedName',
    fullName: 'fullName',
    providerLink: 'providerLink',
  };

  function createComponent() {
    const ProviderRepoTableRow = Vue.extend(providerRepoTableRow);

    return new ProviderRepoTableRow({
      store,
      propsData: {
        repo: {
          ...repo,
        },
      },
    }).$mount();
  }

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a provider repo table row', () => {
    vm = createComponent();

    const providerLink = vm.$el.querySelector('.js-provider-link');
    const statusObject = STATUS_MAP[STATUSES.NONE];

    expect(vm.$el.classList.contains('js-provider-repo')).toBe(true);
    expect(providerLink.href).toMatch(repo.providerLink);
    expect(providerLink.textContent).toMatch(repo.fullName);
    expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
      statusObject.text,
    );

    expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();
    expect(vm.$el.querySelector('.js-import-button')).not.toBeNull();
  });

  it('renders a select2 namespace select', () => {
    vm = createComponent();

    const dropdownTrigger = vm.$el.querySelector('.js-namespace-select');

    expect(dropdownTrigger).not.toBeNull();
    expect(dropdownTrigger.classList.contains('select2-container')).toBe(true);

    dropdownTrigger.click();

    expect(vm.$el.querySelector('.select2-drop')).not.toBeNull();
  });

  it('imports repo when clicking import button', done => {
    const importPath = '/import-path';
    const defaultTargetNamespace = 'user';
    const ciCdOnly = true;
    const mock = new MockAdapter(axios);

    store.dispatch('setInitialData', { importPath, defaultTargetNamespace, ciCdOnly });
    mock.onPost(importPath).replyOnce(200);
    spyOn(store, 'dispatch').and.returnValue(new Promise(() => {}));

    vm = createComponent();

    vm.$el.querySelector('.js-import-button').click();

    setTimeoutPromise()
      .then(() => {
        expect(store.dispatch).toHaveBeenCalledWith('fetchImport', {
          repo,
          newName: repo.sanitizedName,
          targetNamespace: defaultTargetNamespace,
        });
      })
      .then(() => mock.restore())
      .then(done)
      .catch(done.fail);
  });
});
