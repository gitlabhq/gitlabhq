import Vue from 'vue';
import issueTitle from '~/issue_show/issue_title';

describe('Issue Title', () => {
  let IssueTitleComponent;

  beforeEach(() => {
    IssueTitleComponent = Vue.extend(issueTitle);
  });

  it('should render a title', () => {
    const component = new IssueTitleComponent({
      propsData: {
        initialTitle: 'wow',
        endpoint: '/gitlab-org/gitlab-shell/issues/9/rendered_title',
      },
    }).$mount();

    expect(component.$el.classList).toContain('title');
    expect(component.$el.innerHTML).toContain('wow');
  });
});
