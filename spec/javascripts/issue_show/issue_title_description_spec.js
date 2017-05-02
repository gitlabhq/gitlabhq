import Vue from 'vue';
import $ from 'jquery';
import '~/render_math';
import '~/render_gfm';
import issueTitle from '~/issue_show/issue_title_description.vue';
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

  const comps = {
    IssueTitleComponent: {},
  };

  beforeEach(() => {
    comps.IssueTitleComponent = Vue.extend(issueTitle);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, issueShowInterceptor);
  });

  it('should render a title/description and update title/description on update', (done) => {
    Vue.http.interceptors.push(issueShowInterceptor(issueShowData.initialRequest));

    const issueShowComponent = new comps.IssueTitleComponent({
      propsData: {
        candescription: '.css-stuff',
        endpoint: '/gitlab-org/gitlab-shell/issues/9/rendered_title',
      },
    }).$mount();

    // need setTimeout because actual setTimeout in code :P
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
      }, 10);
    }, 10);
    // 10ms is just long enough for the update hook to fire
  });
});
