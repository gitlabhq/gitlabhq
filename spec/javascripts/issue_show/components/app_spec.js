import Vue from 'vue';
import '~/render_math';
import '~/render_gfm';
import issuableApp from '~/issue_show/components/app.vue';
import eventHub from '~/issue_show/event_hub';
import issueShowData from '../mock_data';

function formatText(text) {
  return text.trim().replace(/\s\s+/g, ' ');
}

describe('Issuable output', () => {
  let requestData = issueShowData.initialRequest;

  document.body.innerHTML = '<span id="task_status"></span>';

  const interceptor = (request, next) => {
    next(request.respondWith(JSON.stringify(requestData), {
      status: 200,
    }));
  };

  let vm;

  beforeEach((done) => {
    spyOn(eventHub, '$emit');

    const IssuableDescriptionComponent = Vue.extend(issuableApp);

    requestData = issueShowData.initialRequest;
    Vue.http.interceptors.push(interceptor);

    vm = new IssuableDescriptionComponent({
      propsData: {
        canUpdate: true,
        canDestroy: true,
        canMove: true,
        endpoint: '/gitlab-org/gitlab-shell/issues/9/realtime_changes',
        issuableRef: '#1',
        initialTitleHtml: '',
        initialTitleText: '',
        initialDescriptionHtml: '',
        initialDescriptionText: '',
        markdownPreviewUrl: '/',
        markdownDocs: '/',
        projectsAutocompleteUrl: '/',
        isConfidential: false,
        projectNamespace: '/',
        projectPath: '/',
      },
    }).$mount();

    setTimeout(done);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

    vm.poll.stop();
  });

  it('should render a title/description/edited and update title/description/edited on update', (done) => {
    let editedText;
    Vue.nextTick()
    .then(() => {
      editedText = vm.$el.querySelector('.edited-text');
    })
    .then(() => {
      expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
      expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>this is a title</p>');
      expect(vm.$el.querySelector('.wiki').innerHTML).toContain('<p>this is a description!</p>');
      expect(vm.$el.querySelector('.js-task-list-field').value).toContain('this is a description');
      expect(formatText(editedText.innerText)).toMatch(/Edited[\s\S]+?by Some User/);
      expect(editedText.querySelector('.author_link').href).toMatch(/\/some_user$/);
      expect(editedText.querySelector('time')).toBeTruthy();
    })
    .then(() => {
      requestData = issueShowData.secondRequest;
      vm.poll.makeRequest();
    })
    .then(() => new Promise(resolve => setTimeout(resolve)))
    .then(() => {
      expect(document.querySelector('title').innerText).toContain('2 (#1)');
      expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>2</p>');
      expect(vm.$el.querySelector('.wiki').innerHTML).toContain('<p>42</p>');
      expect(vm.$el.querySelector('.js-task-list-field').value).toContain('42');
      expect(vm.$el.querySelector('.edited-text')).toBeTruthy();
      expect(formatText(vm.$el.querySelector('.edited-text').innerText)).toMatch(/Edited[\s\S]+?by Other User/);
      expect(editedText.querySelector('.author_link').href).toMatch(/\/other_user$/);
      expect(editedText.querySelector('time')).toBeTruthy();
    })
    .then(done)
    .catch(done.fail);
  });

  it('shows actions if permissions are correct', (done) => {
    vm.showForm = true;

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.btn'),
      ).not.toBeNull();

      done();
    });
  });

  it('does not show actions if permissions are incorrect', (done) => {
    vm.showForm = true;
    vm.canUpdate = false;

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.btn'),
      ).toBeNull();

      done();
    });
  });

  it('does not update formState if form is already open', (done) => {
    vm.openForm();

    vm.state.titleText = 'testing 123';

    vm.openForm();

    Vue.nextTick(() => {
      expect(
        vm.store.formState.title,
      ).not.toBe('testing 123');

      done();
    });
  });

  describe('updateIssuable', () => {
    it('fetches new data after update', (done) => {
      spyOn(vm.service, 'getData').and.callThrough();
      spyOn(vm.service, 'updateIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return {
              confidential: false,
              web_url: location.pathname,
            };
          },
        });
      }));

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          vm.service.getData,
        ).toHaveBeenCalled();

        done();
      });
    });

    it('reloads the page if the confidential status has changed', (done) => {
      spyOn(gl.utils, 'visitUrl');
      spyOn(vm.service, 'updateIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return {
              confidential: true,
              web_url: location.pathname,
            };
          },
        });
      }));

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          gl.utils.visitUrl,
        ).toHaveBeenCalledWith(location.pathname);

        done();
      });
    });

    it('correctly updates issuable data', (done) => {
      spyOn(vm.service, 'updateIssuable').and.callFake(() => new Promise((resolve) => {
        resolve();
      }));

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          vm.service.updateIssuable,
        ).toHaveBeenCalledWith(vm.formState);
        expect(
          eventHub.$emit,
        ).toHaveBeenCalledWith('close.form');

        done();
      });
    });

    it('does not redirect if issue has not moved', (done) => {
      spyOn(gl.utils, 'visitUrl');
      spyOn(vm.service, 'updateIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return {
              web_url: location.pathname,
              confidential: vm.isConfidential,
            };
          },
        });
      }));

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          gl.utils.visitUrl,
        ).not.toHaveBeenCalled();

        done();
      });
    });

    it('redirects if issue is moved', (done) => {
      spyOn(gl.utils, 'visitUrl');
      spyOn(vm.service, 'updateIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return {
              web_url: '/testing-issue-move',
              confidential: vm.isConfidential,
            };
          },
        });
      }));

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          gl.utils.visitUrl,
        ).toHaveBeenCalledWith('/testing-issue-move');

        done();
      });
    });

    it('does not update issuable if project move confirm is false', (done) => {
      spyOn(window, 'confirm').and.returnValue(false);
      spyOn(vm.service, 'updateIssuable');

      vm.store.formState.move_to_project_id = 1;

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          vm.service.updateIssuable,
        ).not.toHaveBeenCalled();

        done();
      });
    });

    it('closes form on error', (done) => {
      spyOn(window, 'Flash').and.callThrough();
      spyOn(vm.service, 'updateIssuable').and.callFake(() => new Promise((resolve, reject) => {
        reject();
      }));

      vm.updateIssuable();

      setTimeout(() => {
        expect(
          eventHub.$emit,
        ).toHaveBeenCalledWith('close.form');
        expect(
          window.Flash,
        ).toHaveBeenCalledWith('Error updating issue');

        done();
      });
    });
  });

  describe('deleteIssuable', () => {
    it('changes URL when deleted', (done) => {
      spyOn(gl.utils, 'visitUrl');
      spyOn(vm.service, 'deleteIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return { web_url: '/test' };
          },
        });
      }));

      vm.deleteIssuable();

      setTimeout(() => {
        expect(
          gl.utils.visitUrl,
        ).toHaveBeenCalledWith('/test');

        done();
      });
    });

    it('stops polling when deleting', (done) => {
      spyOn(gl.utils, 'visitUrl');
      spyOn(vm.poll, 'stop').and.callThrough();
      spyOn(vm.service, 'deleteIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return { web_url: '/test' };
          },
        });
      }));

      vm.deleteIssuable();

      setTimeout(() => {
        expect(
          vm.poll.stop,
        ).toHaveBeenCalledWith();

        done();
      });
    });

    it('closes form on error', (done) => {
      spyOn(window, 'Flash').and.callThrough();
      spyOn(vm.service, 'deleteIssuable').and.callFake(() => new Promise((resolve, reject) => {
        reject();
      }));

      vm.deleteIssuable();

      setTimeout(() => {
        expect(
          eventHub.$emit,
        ).toHaveBeenCalledWith('close.form');
        expect(
          window.Flash,
        ).toHaveBeenCalledWith('Error deleting issue');

        done();
      });
    });
  });

  describe('open form', () => {
    it('shows locked warning if form is open & data is different', (done) => {
      Vue.nextTick()
        .then(() => {
          vm.openForm();

          requestData = issueShowData.secondRequest;
          vm.poll.makeRequest();
        })
        .then(() => new Promise(resolve => setTimeout(resolve)))
        .then(() => {
          expect(
            vm.formState.lockedWarningVisible,
          ).toBeTruthy();

          expect(
            vm.$el.querySelector('.alert'),
          ).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
