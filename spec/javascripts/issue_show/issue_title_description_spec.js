import Vue from 'vue';
import $ from 'jquery';
import '~/render_math';
import '~/render_gfm';
import issueTitleDescription from '~/issue_show/issue_title_description.vue';
import issueShowData from './mock_data';

window.$ = $;

function formatText(text) {
  return text.trim().replace(/\s\s+/g, ' ');
}

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

  it('should render a title/description/edited and update title/description/edited on update', (done) => {
    Vue.http.interceptors.push(issueShowInterceptor(issueShowData.initialRequest));

    const issueShowComponent = new IssueTitleDescriptionComponent({
      propsData: {
        canUpdateIssue: '.css-stuff',
        endpoint: '/gitlab-org/gitlab-shell/issues/9/rendered_title',
      },
    }).$mount();

    setTimeout(() => {
      const editedText = issueShowComponent.$el.querySelector('.edited-text');

      expect(document.querySelector('title').innerText).toContain('this is a title (#1)');
      expect(issueShowComponent.$el.querySelector('.title').innerHTML).toContain('<p>this is a title</p>');
      expect(issueShowComponent.$el.querySelector('.wiki').innerHTML).toContain('<p>this is a description!</p>');
      expect(issueShowComponent.$el.querySelector('.js-task-list-field').innerText).toContain('this is a description');
      expect(formatText(editedText.innerText)).toMatch(/Edited[\s\S]+?by Some User/);
      expect(editedText.querySelector('.author_link').href).toMatch(/\/some_user$/);
      expect(editedText.querySelector('time')).toBeTruthy();

      Vue.http.interceptors.push(issueShowInterceptor(issueShowData.secondRequest));

      setTimeout(() => {
        expect(document.querySelector('title').innerText).toContain('2 (#1)');
        expect(issueShowComponent.$el.querySelector('.title').innerHTML).toContain('<p>2</p>');
        expect(issueShowComponent.$el.querySelector('.wiki').innerHTML).toContain('<p>42</p>');
        expect(issueShowComponent.$el.querySelector('.js-task-list-field').innerText).toContain('42');
        expect(issueShowComponent.$el.querySelector('.edited-text')).toBeTruthy();
        expect(formatText(issueShowComponent.$el.querySelector('.edited-text').innerText)).toMatch(/Edited[\s\S]+?by Other User/);
        expect(editedText.querySelector('.author_link').href).toMatch(/\/other_user$/);
        expect(editedText.querySelector('time')).toBeTruthy();

        done();
      });
    });
  });
});
