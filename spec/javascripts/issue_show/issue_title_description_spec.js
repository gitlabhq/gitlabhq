import Vue from 'vue';
import $ from 'jquery';
import '~/render_math';
import '~/render_gfm';
import issueTitle from '~/issue_show/issue_title_description.vue';
import issueShowData from './mock_data';

window.$ = $;

const issueShowInterceptor = (request, next) => {
  next(request.respondWith(JSON.stringify(issueShowData), {
    status: 200,
  }));
};

fdescribe('Issue Title', () => {
  document.body.innerHTML = '<span id="task_status"></span>';

  const comps = {
    IssueTitleComponent: {},
  };

  beforeEach(() => {
    comps.IssueTitleComponent = Vue.extend(issueTitle);
    Vue.http.interceptors.push(issueShowInterceptor);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(
      Vue.http.interceptors, issueShowInterceptor,
    );
  });

  it('should render a title', (done) => {
    const issueShowComponent = new comps.IssueTitleComponent({
      propsData: {
        candescription: '.css-stuff',
        endpoint: '/gitlab-org/gitlab-shell/issues/9/rendered_title',
      },
    }).$mount();

    // need setTimeout because actual setTimeout in code :P
    setTimeout(() => {
      expect(document.querySelector('title').innerText)
        .toContain('this is a title (#1)');

      expect(issueShowComponent.$el.querySelector('.title').innerHTML)
        .toContain('<p>this is a title</p>');

      expect(issueShowComponent.$el.querySelector('.wiki').innerHTML)
        .toContain('<p>this is a description!</p>');

      const hiddenText = issueShowComponent.$el
        .querySelector('.js-task-list-field').innerText;

      expect(hiddenText)
        .toContain('this is a description');

      done();
    }, 10);
    // 10ms is just long enough for the update hook to fire
  });
});
