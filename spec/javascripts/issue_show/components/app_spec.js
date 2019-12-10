/* eslint-disable no-unused-vars */
import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import setTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import GLDropdown from '~/gl_dropdown';
import axios from '~/lib/utils/axios_utils';
import '~/behaviors/markdown/render_gfm';
import issuableApp from '~/issue_show/components/app.vue';
import eventHub from '~/issue_show/event_hub';
import issueShowData from '../mock_data';

function formatText(text) {
  return text.trim().replace(/\s\s+/g, ' ');
}

const REALTIME_REQUEST_STACK = [issueShowData.initialRequest, issueShowData.secondRequest];

describe('Issuable output', () => {
  let mock;
  let realtimeRequestCount = 0;
  let vm;

  beforeEach(done => {
    setFixtures(`
      <div>
        <div class="detail-page-description content-block">
        <details open>
          <summary>One</summary>
        </details>
        <details>
          <summary>Two</summary>
        </details>
      </div>
        <div class="flash-container"></div>
        <span id="task_status"></span>
      </div>
    `);
    spyOn(eventHub, '$emit');

    const IssuableDescriptionComponent = Vue.extend(issuableApp);

    mock = new MockAdapter(axios);
    mock.onGet('/gitlab-org/gitlab-shell/issues/9/realtime_changes/realtime_changes').reply(() => {
      const res = Promise.resolve([200, REALTIME_REQUEST_STACK[realtimeRequestCount]]);
      realtimeRequestCount += 1;
      return res;
    });

    vm = new IssuableDescriptionComponent({
      propsData: {
        canUpdate: true,
        canDestroy: true,
        endpoint: '/gitlab-org/gitlab-shell/issues/9/realtime_changes',
        updateEndpoint: gl.TEST_HOST,
        issuableRef: '#1',
        initialTitleHtml: '',
        initialTitleText: '',
        initialDescriptionHtml: 'test',
        initialDescriptionText: 'test',
        lockVersion: 1,
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        projectNamespace: '/',
        projectPath: '/',
        issuableTemplateNamesPath: '/issuable-templates-path',
      },
    }).$mount();

    setTimeout(done);
  });

  afterEach(() => {
    mock.restore();
    realtimeRequestCount = 0;

    vm.poll.stop();
    vm.$destroy();
  });

  it('should render a title/description/edited and update title/description/edited on update', done => {
    let editedText;
    Vue.nextTick()
      .then(() => {
        editedText = vm.$el.querySelector('.edited-text');
      })
      .then(() => {
        expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
        expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>this is a title</p>');
        expect(vm.$el.querySelector('.md').innerHTML).toContain('<p>this is a description!</p>');
        expect(vm.$el.querySelector('.js-task-list-field').value).toContain(
          'this is a description',
        );

        expect(formatText(editedText.innerText)).toMatch(/Edited[\s\S]+?by Some User/);
        expect(editedText.querySelector('.author-link').href).toMatch(/\/some_user$/);
        expect(editedText.querySelector('time')).toBeTruthy();
        expect(vm.state.lock_version).toEqual(1);
      })
      .then(() => {
        vm.poll.makeRequest();
      })
      .then(() => new Promise(resolve => setTimeout(resolve)))
      .then(() => {
        expect(document.querySelector('title').innerText).toContain('2 (#1)');
        expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>2</p>');
        expect(vm.$el.querySelector('.md').innerHTML).toContain('<p>42</p>');
        expect(vm.$el.querySelector('.js-task-list-field').value).toContain('42');
        expect(vm.$el.querySelector('.edited-text')).toBeTruthy();
        expect(formatText(vm.$el.querySelector('.edited-text').innerText)).toMatch(
          /Edited[\s\S]+?by Other User/,
        );

        expect(editedText.querySelector('.author-link').href).toMatch(/\/other_user$/);
        expect(editedText.querySelector('time')).toBeTruthy();
        expect(vm.state.lock_version).toEqual(2);
      })
      .then(done)
      .catch(done.fail);
  });

  it('shows actions if permissions are correct', done => {
    vm.showForm = true;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.btn')).not.toBeNull();

      done();
    });
  });

  it('does not show actions if permissions are incorrect', done => {
    vm.showForm = true;
    vm.canUpdate = false;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.btn')).toBeNull();

      done();
    });
  });

  it('does not update formState if form is already open', done => {
    vm.updateAndShowForm();

    vm.state.titleText = 'testing 123';

    vm.updateAndShowForm();

    Vue.nextTick(() => {
      expect(vm.store.formState.title).not.toBe('testing 123');

      done();
    });
  });

  describe('updateIssuable', () => {
    it('fetches new data after update', done => {
      spyOn(vm, 'updateStoreState').and.callThrough();
      spyOn(vm.service, 'getData').and.callThrough();
      spyOn(vm.service, 'updateIssuable').and.returnValue(
        Promise.resolve({
          data: { web_url: window.location.pathname },
        }),
      );

      vm.updateIssuable()
        .then(() => {
          expect(vm.updateStoreState).toHaveBeenCalled();
          expect(vm.service.getData).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('correctly updates issuable data', done => {
      spyOn(vm.service, 'updateIssuable').and.returnValue(
        Promise.resolve({
          data: { web_url: window.location.pathname },
        }),
      );

      vm.updateIssuable()
        .then(() => {
          expect(vm.service.updateIssuable).toHaveBeenCalledWith(vm.formState);
          expect(eventHub.$emit).toHaveBeenCalledWith('close.form');
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not redirect if issue has not moved', done => {
      const visitUrl = spyOnDependency(issuableApp, 'visitUrl');
      spyOn(vm.service, 'updateIssuable').and.returnValue(
        Promise.resolve({
          data: {
            web_url: window.location.pathname,
            confidential: vm.isConfidential,
          },
        }),
      );

      vm.updateIssuable();

      setTimeout(() => {
        expect(visitUrl).not.toHaveBeenCalled();
        done();
      });
    });

    it('redirects if returned web_url has changed', done => {
      const visitUrl = spyOnDependency(issuableApp, 'visitUrl');
      spyOn(vm.service, 'updateIssuable').and.returnValue(
        Promise.resolve({
          data: {
            web_url: '/testing-issue-move',
            confidential: vm.isConfidential,
          },
        }),
      );

      vm.updateIssuable();

      setTimeout(() => {
        expect(visitUrl).toHaveBeenCalledWith('/testing-issue-move');
        done();
      });
    });

    describe('shows dialog when issue has unsaved changed', () => {
      it('confirms on title change', done => {
        vm.showForm = true;
        vm.state.titleText = 'title has changed';
        const e = { returnValue: null };
        vm.handleBeforeUnloadEvent(e);
        Vue.nextTick(() => {
          expect(e.returnValue).not.toBeNull();

          done();
        });
      });

      it('confirms on description change', done => {
        vm.showForm = true;
        vm.state.descriptionText = 'description has changed';
        const e = { returnValue: null };
        vm.handleBeforeUnloadEvent(e);
        Vue.nextTick(() => {
          expect(e.returnValue).not.toBeNull();

          done();
        });
      });

      it('does nothing when nothing has changed', done => {
        const e = { returnValue: null };
        vm.handleBeforeUnloadEvent(e);
        Vue.nextTick(() => {
          expect(e.returnValue).toBeNull();

          done();
        });
      });
    });

    describe('error when updating', () => {
      it('closes form on error', done => {
        spyOn(vm.service, 'updateIssuable').and.callFake(() => Promise.reject());
        vm.updateIssuable();

        setTimeout(() => {
          expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `Error updating issue`,
          );

          done();
        });
      });

      it('returns the correct error message for issuableType', done => {
        spyOn(vm.service, 'updateIssuable').and.callFake(() => Promise.reject());
        vm.issuableType = 'merge request';

        Vue.nextTick(() => {
          vm.updateIssuable();

          setTimeout(() => {
            expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
            expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
              `Error updating merge request`,
            );

            done();
          });
        });
      });

      it('shows error message from backend if exists', done => {
        const msg = 'Custom error message from backend';
        spyOn(vm.service, 'updateIssuable').and.callFake(
          // eslint-disable-next-line prefer-promise-reject-errors
          () => Promise.reject({ response: { data: { errors: [msg] } } }),
        );

        vm.updateIssuable();
        setTimeout(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `${vm.defaultErrorMessage}. ${msg}`,
          );

          done();
        });
      });
    });
  });

  it('opens recaptcha modal if update rejected as spam', done => {
    function mockScriptSrc() {
      const recaptchaChild = vm.$children.find(
        // eslint-disable-next-line no-underscore-dangle
        child => child.$options._componentTag === 'recaptcha-modal',
      );

      recaptchaChild.scriptSrc = '//scriptsrc';
    }

    let modal;
    const promise = new Promise(resolve => {
      resolve({
        data: {
          recaptcha_html: '<div class="g-recaptcha">recaptcha_html</div>',
        },
      });
    });

    spyOn(vm.service, 'updateIssuable').and.returnValue(promise);

    vm.canUpdate = true;
    vm.showForm = true;

    vm.$nextTick()
      .then(() => mockScriptSrc())
      .then(() => vm.updateIssuable())
      .then(promise)
      .then(() => setTimeoutPromise())
      .then(() => {
        modal = vm.$el.querySelector('.js-recaptcha-modal');

        expect(modal.style.display).not.toEqual('none');
        expect(modal.querySelector('.g-recaptcha').textContent).toEqual('recaptcha_html');
        expect(document.body.querySelector('.js-recaptcha-script').src).toMatch('//scriptsrc');
      })
      .then(() => modal.querySelector('.close').click())
      .then(() => vm.$nextTick())
      .then(() => {
        expect(modal.style.display).toEqual('none');
        expect(document.body.querySelector('.js-recaptcha-script')).toBeNull();
      })
      .then(done)
      .catch(done.fail);
  });

  describe('deleteIssuable', () => {
    it('changes URL when deleted', done => {
      const visitUrl = spyOnDependency(issuableApp, 'visitUrl');
      spyOn(vm.service, 'deleteIssuable').and.returnValue(
        Promise.resolve({
          data: {
            web_url: '/test',
          },
        }),
      );

      vm.deleteIssuable();

      setTimeout(() => {
        expect(visitUrl).toHaveBeenCalledWith('/test');

        done();
      });
    });

    it('stops polling when deleting', done => {
      spyOnDependency(issuableApp, 'visitUrl');
      spyOn(vm.poll, 'stop').and.callThrough();
      spyOn(vm.service, 'deleteIssuable').and.returnValue(
        Promise.resolve({
          data: {
            web_url: '/test',
          },
        }),
      );

      vm.deleteIssuable();

      setTimeout(() => {
        expect(vm.poll.stop).toHaveBeenCalledWith();

        done();
      });
    });

    it('closes form on error', done => {
      spyOn(vm.service, 'deleteIssuable').and.returnValue(Promise.reject());

      vm.deleteIssuable();

      setTimeout(() => {
        expect(eventHub.$emit).not.toHaveBeenCalledWith('close.form');
        expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
          'Error deleting issue',
        );

        done();
      });
    });
  });

  describe('updateAndShowForm', () => {
    it('shows locked warning if form is open & data is different', done => {
      vm.$nextTick()
        .then(() => {
          vm.updateAndShowForm();

          vm.poll.makeRequest();

          return new Promise(resolve => {
            vm.$watch('formState.lockedWarningVisible', value => {
              if (value) resolve();
            });
          });
        })
        .then(() => {
          expect(vm.formState.lockedWarningVisible).toEqual(true);
          expect(vm.formState.lock_version).toEqual(1);
          expect(vm.$el.querySelector('.alert')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestTemplatesAndShowForm', () => {
    beforeEach(() => {
      spyOn(vm, 'updateAndShowForm');
    });

    it('shows the form if template names request is successful', done => {
      const mockData = [{ name: 'Bug' }];
      mock.onGet('/issuable-templates-path').reply(() => Promise.resolve([200, mockData]));

      vm.requestTemplatesAndShowForm()
        .then(() => {
          expect(vm.updateAndShowForm).toHaveBeenCalledWith(mockData);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows the form if template names request failed', done => {
      mock
        .onGet('/issuable-templates-path')
        .reply(() => Promise.reject(new Error('something went wrong')));

      vm.requestTemplatesAndShowForm()
        .then(() => {
          expect(document.querySelector('.flash-container .flash-text').textContent).toContain(
            'Error updating issue',
          );

          expect(vm.updateAndShowForm).toHaveBeenCalledWith();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('show inline edit button', () => {
    it('should not render by default', () => {
      expect(vm.$el.querySelector('.title-container .note-action-button')).toBeDefined();
    });

    it('should render if showInlineEditButton', () => {
      vm.showInlineEditButton = true;

      expect(vm.$el.querySelector('.title-container .note-action-button')).toBeDefined();
    });
  });

  describe('updateStoreState', () => {
    it('should make a request and update the state of the store', done => {
      const data = { foo: 1 };
      spyOn(vm.store, 'updateState');
      spyOn(vm.service, 'getData').and.returnValue(Promise.resolve({ data }));

      vm.updateStoreState()
        .then(() => {
          expect(vm.service.getData).toHaveBeenCalled();
          expect(vm.store.updateState).toHaveBeenCalledWith(data);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should show error message if store update fails', done => {
      spyOn(vm.service, 'getData').and.returnValue(Promise.reject());
      vm.issuableType = 'merge request';

      vm.updateStoreState()
        .then(() => {
          expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(
            `Error updating ${vm.issuableType}`,
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('issueChanged', () => {
    beforeEach(() => {
      vm.store.formState.title = '';
      vm.store.formState.description = '';
      vm.initialDescriptionText = '';
      vm.initialTitleText = '';
    });

    it('returns true when title is changed', () => {
      vm.store.formState.title = 'RandomText';

      expect(vm.issueChanged).toBe(true);
    });

    it('returns false when title is empty null', () => {
      vm.store.formState.title = null;

      expect(vm.issueChanged).toBe(false);
    });

    it('returns false when `initialTitleText` is null and `formState.title` is empty string', () => {
      vm.store.formState.title = '';
      vm.initialTitleText = null;

      expect(vm.issueChanged).toBe(false);
    });

    it('returns true when description is changed', () => {
      vm.store.formState.description = 'RandomText';

      expect(vm.issueChanged).toBe(true);
    });

    it('returns false when description is empty null', () => {
      vm.store.formState.title = null;

      expect(vm.issueChanged).toBe(false);
    });

    it('returns false when `initialDescriptionText` is null and `formState.description` is empty string', () => {
      vm.store.formState.description = '';
      vm.initialDescriptionText = null;

      expect(vm.issueChanged).toBe(false);
    });
  });
});
