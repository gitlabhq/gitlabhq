//= require vue_common_component/commit

describe('Commit component', () => {

  let props;
  let component;


  it('should render a code-fork icon if it does not represent a tag', () => {
    fixture.set('<div class="test-commit-container"></div>');
    component = new window.gl.CommitComponent({
      el: document.querySelector('.test-commit-container'),
      propsData: {
        tag: false,
        ref: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commit_url: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        short_sha: 'b7836edd',
        title: 'Commit message',
        author: {
          avatar_url: 'https://gitlab.com/uploads/user/avatar/300478/avatar.png',
          web_url: 'https://gitlab.com/jschatz1',
          username: 'jschatz1',
        },
      },
    });

    expect(component.$el.querySelector('.icon-container i').classList).toContain('fa-code-fork');
  });

  describe('Given all the props', () => {
    beforeEach(() => {
      fixture.set('<div class="test-commit-container"></div>');

      props = {
        tag: true,
        ref: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commit_url: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        short_sha: 'b7836edd',
        title: 'Commit message',
        author: {
          avatar_url: 'https://gitlab.com/uploads/user/avatar/300478/avatar.png',
          web_url: 'https://gitlab.com/jschatz1',
          username: 'jschatz1',
        },
      };

      component = new window.gl.CommitComponent({
        el: document.querySelector('.test-commit-container'),
        propsData: props,
      });
    });

    it('should render a tag icon if it represents a tag', () => {
      expect(component.$el.querySelector('.icon-container i').classList).toContain('fa-tag');
    });

    it('should render a link to the ref url', () => {
      expect(component.$el.querySelector('.branch-name').getAttribute('href')).toEqual(props.ref.ref_url);
    });

    it('should render the ref name', () => {
      expect(component.$el.querySelector('.branch-name').textContent).toContain(props.ref.name);
    });

    it('should render the commit short sha with a link to the commit url', () => {
      expect(component.$el.querySelector('.commit-id').getAttribute('href')).toEqual(props.commit_url);
      expect(component.$el.querySelector('.commit-id').textContent).toContain(props.short_sha);
    });

    describe('Given commit title and author props', () => {
      it('Should render a link to the author profile', () => {
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container').getAttribute('href')
        ).toEqual(props.author.web_url);
      });

      it('Should render the author avatar with title and alt attributes', () => {
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container img').getAttribute('title')
        ).toContain(props.author.username);
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container img').getAttribute('alt')
        ).toContain(`${props.author.username}'s avatar`);
      });
    });

    it('should render the commit title', () => {
      expect(
        component.$el.querySelector('a.commit-row-message').getAttribute('href')
      ).toEqual(props.commit_url);
      expect(
        component.$el.querySelector('a.commit-row-message').textContent
      ).toContain(props.title);
    });
  });

  describe('When commit title is not provided', () => {
    it('Should render default message', () => {
      fixture.set('<div class="test-commit-container"></div>');
      props = {
        tag: false,
        ref: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commit_url: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        short_sha: 'b7836edd',
        title: null,
        author: {},
      };

      component = new window.gl.CommitComponent({
        el: document.querySelector('.test-commit-container'),
        propsData: props,
      });

      expect(
        component.$el.querySelector('.commit-title span').textContent
      ).toContain('Cant find HEAD commit for this branch');
    });
  });
});
