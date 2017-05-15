import Vue from 'vue';
import $ from 'jquery';
import '~/render_math';
import '~/render_gfm';
import issueTitleDescription from '~/issue_show/issue_title_description.vue';
import issueShowData from './mock_data';

window.$ = $;

const issueShowInterceptor = data => (request, next) => {
  next(request.respondWith(JSON.stringify(data), {
    status: 200,
    headers: {
      'POLL-INTERVAL': 1,
    },
  }));
};

describe('Issue Title', () => {
  document.body.innerHTML = '<span id="task_status"></span>';

  let IssueTitleDescriptionComponent;

  beforeEach(() => {
    IssueTitleDescriptionComponent = Vue.extend(issueTitleDescription);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, issueShowInterceptor);
  });

  it('should render a title/description and update title/description on update', (done) => {
    Vue.http.interceptors.push(issueShowInterceptor(issueShowData.initialRequest));

    const issueShowComponent = new IssueTitleDescriptionComponent({
      propsData: {
        canUpdateIssue: '.css-stuff',
        endpoint: '/gitlab-org/gitlab-shell/issues/9/realtime_changes',
      },
    }).$mount();

    setTimeout(() => {
      expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
      expect(issueShowComponent.$el.querySelector('.title').innerHTML).toContain('<p>this is a title</p>');
      expect(issueShowComponent.$el.querySelector('.wiki').innerHTML).toContain('<p>this is a description!</p>');
      expect(issueShowComponent.$el.querySelector('.js-task-list-field').innerText).toContain('this is a description');

      Vue.http.interceptors.push(issueShowInterceptor(issueShowData.secondRequest));

      setTimeout(() => {
        expect(document.querySelector('title').innerText).toContain('2 (#1)');
        expect(issueShowComponent.$el.querySelector('.title').innerHTML).toContain('<p>2</p>');
        expect(issueShowComponent.$el.querySelector('.wiki').innerHTML).toContain('<p>42</p>');
        expect(issueShowComponent.$el.querySelector('.js-task-list-field').innerText).toContain('42');

        done();
      });
    });
  });
});
