import Vue from 'vue';
import RelatedIssuesRoot from '~/issuable/related_issues/components/related_issues_root.vue';

const defaultProps = {
  endpoint: '/foo/bar/issues/1/related_issues',
  currentNamespacePath: 'foo',
  currentProjectPath: 'bar',
};

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(RelatedIssuesRoot);

  return new Component({
    propsData,
  })
    .$mount();
};

const issuable1 = {
  namespace_full_path: 'foo',
  project_path: 'bar',
  iid: '123',
  title: 'issue1',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};
const issuable1Reference = `${issuable1.namespace_full_path}/${issuable1.project_path}#${issuable1.iid}`;

const issuable2 = {
  namespace_full_path: 'foo',
  project_path: 'bar',
  iid: '124',
  title: 'issue2',
  path: '/foo/bar/issues/124',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/124/related_issues/2',
};
const issuable2Reference = `${issuable2.namespace_full_path}/${issuable2.project_path}#${issuable2.iid}`;

describe('RelatedIssuesRoot', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1Reference, issuable1);
        vm.store.setRelatedIssues([issuable1Reference]);
      });

      it('remove related issue and succeeds', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1Reference);

        setTimeout(() => {
          expect(vm.computedRelatedIssues).toEqual([]);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });

      it('remove related issue, fails, and restores to related issues', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 422,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1Reference);

        setTimeout(() => {
          expect(vm.computedRelatedIssues.length).toEqual(1);
          expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });
    });

    describe('onShowAddRelatedIssuesForm', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('show add related issues form', () => {
        vm.onShowAddRelatedIssuesForm();

        expect(vm.isFormVisible).toEqual(true);
      });
    });

    describe('onAddIssuableFormIssuableRemoveRequest', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1Reference, issuable1);
        vm.store.setPendingRelatedIssues([issuable1Reference]);
      });

      it('remove pending related issue', () => {
        vm.onAddIssuableFormIssuableRemoveRequest(issuable1Reference);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('onAddIssuableFormSubmit', () => {
      describe('when service.addRelatedIssues is succeeding', () => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 200,
          }));
        };

        beforeEach(() => {
          vm = createComponent(defaultProps);
          vm.store.addToIssueMap(issuable1Reference, issuable1);
          vm.store.addToIssueMap(issuable2Reference, issuable2);

          Vue.http.interceptors.push(interceptor);
        });

        afterEach(() => {
          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
        });

        it('submit pending issues as related issues', (done) => {
          vm.store.setPendingRelatedIssues([issuable1Reference]);
          vm.onAddIssuableFormSubmit();

          setTimeout(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(1);
            expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);

            done();
          });
        });

        it('submit multiple pending issues as related issues', (done) => {
          vm.store.setPendingRelatedIssues([issuable1Reference, issuable2Reference]);
          vm.onAddIssuableFormSubmit();

          setTimeout(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(2);
            expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);
            expect(vm.computedRelatedIssues[1].reference).toEqual(issuable2Reference);

            done();
          });
        });
      });

      describe('when service.addRelatedIssues fails', () => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 422,
          }));
        };

        beforeEach(() => {
          vm = createComponent(defaultProps);
          vm.store.addToIssueMap(issuable1Reference, issuable1);
          vm.store.addToIssueMap(issuable2Reference, issuable2);

          Vue.http.interceptors.push(interceptor);
        });

        afterEach(() => {
          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
        });

        it('submit pending issues as related issues fails and restores to pending related issues', (done) => {
          vm.store.setPendingRelatedIssues([issuable1Reference]);
          vm.onAddIssuableFormSubmit();

          setTimeout(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(1);
            expect(vm.computedPendingRelatedIssues[0].reference).toEqual(issuable1Reference);
            expect(vm.computedRelatedIssues.length).toEqual(0);

            done();
          });
        });
      });
    });

    describe('onAddIssuableFormCancel', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.isFormVisible = true;
        vm.inputValue = 'foo';
      });

      it('when canceling and hiding add issuable form', () => {
        vm.onAddIssuableFormCancel();

        expect(vm.isFormVisible).toEqual(false);
        expect(vm.inputValue).toEqual('');
        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('fetchRelatedIssues', () => {
      const interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([issuable1, issuable2]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        vm = createComponent(defaultProps);

        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('fetching related issues', (done) => {
        vm.fetchRelatedIssues();

        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.computedRelatedIssues.length).toEqual(2);
            expect(vm.computedRelatedIssues[0].reference).toEqual(issuable1Reference);
            expect(vm.computedRelatedIssues[1].reference).toEqual(issuable2Reference);

            done();
          });
        });
      });
    });
  });
});
