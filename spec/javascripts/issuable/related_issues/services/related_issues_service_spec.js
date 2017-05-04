import _ from 'underscore';
import Vue from 'vue';
import RelatedIssuesService from '~/issuable/related_issues/services/related_issues_service';

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};

describe('RelatedIssuesService', () => {
  let service;

  beforeEach(() => {
    service = new RelatedIssuesService('');
  });

  describe('fetchIssueInfo', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(issuable1), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('fetch issue info', (done) => {
      service.fetchIssueInfo('...')
        .then(res => res.json())
        .then((issue) => {
          expect(issue).toEqual(issuable1);
          done();
        })
        .catch((err) => {
          done.fail(`Failed to fetch issue:\n${err}`);
        });
    });
  });

  describe('fetchRelatedIssues', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([issuable1]), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('fetch related issues', (done) => {
      service.fetchRelatedIssues()
        .then(res => res.json())
        .then((relatedIssues) => {
          expect(relatedIssues).toEqual([issuable1]);
          done();
        })
        .catch((err) => {
          done.fail(`Failed to fetch related issues:\n${err}`);
        });
    });
  });

  describe('addRelatedIssues', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({
        message: `${issuable1.reference} was successfully related`,
        status: 'success',
      }), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('add related issues', (done) => {
      service.addRelatedIssues([issuable1.reference])
        .then(res => res.json())
        .then((resData) => {
          expect(resData.status).toEqual('success');
          done();
        })
        .catch((err) => {
          done.fail(`Failed to add related issues:\n${err}`);
        });
    });
  });

  describe('removeRelatedIssue', () => {
    const interceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({
        message: 'Relation was removed',
        status: 'success',
      }), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(interceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('remove related issue', (done) => {
      service.removeRelatedIssue('...')
        .then(res => res.json())
        .then((resData) => {
          expect(resData.status).toEqual('success');
          done();
        })
        .catch((err) => {
          done.fail(`Failed to fetch issue:\n${err}`);
        });
    });
  });
});
