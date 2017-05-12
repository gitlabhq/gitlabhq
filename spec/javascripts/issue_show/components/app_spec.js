import Vue from 'vue';
import '~/render_math';
import '~/render_gfm';
import issuableApp from '~/issue_show/components/app.vue';
import eventHub from '~/issue_show/event_hub';
import issueShowData from '../mock_data';

const issueShowInterceptor = data => (request, next) => {
  next(request.respondWith(JSON.stringify(data), {
    status: 200,
    headers: {
      'POLL-INTERVAL': 1,
    },
  }));
};

describe('Issuable output', () => {
  document.body.innerHTML = '<span id="task_status"></span>';

  let vm;

  beforeEach(() => {
    const IssuableDescriptionComponent = Vue.extend(issuableApp);
    Vue.http.interceptors.push(issueShowInterceptor(issueShowData.initialRequest));

    spyOn(eventHub, '$emit');

    vm = new IssuableDescriptionComponent({
      propsData: {
        canUpdate: true,
        canDestroy: true,
        endpoint: '/gitlab-org/gitlab-shell/issues/9/rendered_title',
        issuableRef: '#1',
        initialTitle: '',
        initialDescriptionHtml: '',
        initialDescriptionText: '',
        showForm: false,
      },
    }).$mount();
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, issueShowInterceptor);
  });

  it('should render a title/description and update title/description on update', (done) => {
    setTimeout(() => {
      expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
      expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>this is a title</p>');
      expect(vm.$el.querySelector('.wiki').innerHTML).toContain('<p>this is a description!</p>');
      expect(vm.$el.querySelector('.js-task-list-field').value).toContain('this is a description');

      Vue.http.interceptors.push(issueShowInterceptor(issueShowData.secondRequest));

      setTimeout(() => {
        expect(document.querySelector('title').innerText).toContain('2 (#1)');
        expect(vm.$el.querySelector('.title').innerHTML).toContain('<p>2</p>');
        expect(vm.$el.querySelector('.wiki').innerHTML).toContain('<p>42</p>');
        expect(vm.$el.querySelector('.js-task-list-field').value).toContain('42');

        done();
      });
    });
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

  describe('updateIssuable', () => {
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
            return { path: '/test' };
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

    it('stops polling when deleteing', (done) => {
      spyOn(gl.utils, 'visitUrl');
      spyOn(vm.poll, 'stop');
      spyOn(vm.service, 'deleteIssuable').and.callFake(() => new Promise((resolve) => {
        resolve({
          json() {
            return { path: '/test' };
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
});
