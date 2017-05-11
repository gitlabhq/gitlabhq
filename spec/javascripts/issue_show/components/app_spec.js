import Vue from 'vue';
import '~/render_math';
import '~/render_gfm';
import issuableApp from '~/issue_show/components/app.vue';
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

    vm = new IssuableDescriptionComponent({
      propsData: {
        canUpdate: true,
        endpoint: '/gitlab-org/gitlab-shell/issues/9/rendered_title',
        issuableRef: '#1',
        initialTitle: '',
        initialDescriptionHtml: '',
        initialDescriptionText: '',
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
});
