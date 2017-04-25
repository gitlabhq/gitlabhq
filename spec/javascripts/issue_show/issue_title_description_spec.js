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

describe('Issue Title', () => {
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
        .toContain('this is a title');
      expect(issueShowComponent.$el.querySelector('.title').innerHTML)
        .toContain('<p>this is a title</p>');
      expect(issueShowComponent.$el.querySelector('.wiki').innerHTML)
        .toContain('<p>this is a description!</p>');
      expect(issueShowComponent.$el.querySelector('.js-task-list-field').innerText)
        .toContain('this is a description');
      done();
    }, 10);
    // 10ms is just long enough for the update hook to fire
  });
});
