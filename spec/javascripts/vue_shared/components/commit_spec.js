import Vue from 'vue';
import commitComp from '~/vue_shared/components/commit.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Commit component', () => {
  let props;
  let component;
  let CommitComponent;

  beforeEach(() => {
    CommitComponent = Vue.extend(commitComp);
  });

  afterEach(() => {
    component.$destroy();
  });

  it('should render a fork icon if it does not represent a tag', () => {
    component = mountComponent(CommitComponent, {
      tag: false,
      commitRef: {
        name: 'master',
        ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
      },
      commitUrl:
        'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
      shortSha: 'b7836edd',
      title: 'Commit message',
      author: {
        avatar_url: 'https://gitlab.com/uploads/-/system/user/avatar/300478/avatar.png',
        web_url: 'https://gitlab.com/jschatz1',
        path: '/jschatz1',
        username: 'jschatz1',
      },
    });

    expect(component.$el.querySelector('.icon-container').children).toContain('svg');
  });

  describe('Given all the props', () => {
    beforeEach(() => {
      props = {
        tag: true,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: 'Commit message',
        author: {
          avatar_url: 'https://gitlab.com/uploads/-/system/user/avatar/300478/avatar.png',
          web_url: 'https://gitlab.com/jschatz1',
          path: '/jschatz1',
          username: 'jschatz1',
        },
      };

      component = mountComponent(CommitComponent, props);
    });

    it('should render a tag icon if it represents a tag', () => {
      expect(component.$el.querySelector('.icon-container svg.ic-tag')).not.toBeNull();
    });

    it('should render a link to the ref url', () => {
      expect(component.$el.querySelector('.ref-name').getAttribute('href')).toEqual(
        props.commitRef.ref_url,
      );
    });

    it('should render the ref name', () => {
      expect(component.$el.querySelector('.ref-name').textContent).toContain(props.commitRef.name);
    });

    it('should render the commit short sha with a link to the commit url', () => {
      expect(component.$el.querySelector('.commit-sha').getAttribute('href')).toEqual(
        props.commitUrl,
      );

      expect(component.$el.querySelector('.commit-sha').textContent).toContain(props.shortSha);
    });

    it('should render icon for commit', () => {
      expect(
        component.$el.querySelector('.js-commit-icon use').getAttribute('xlink:href'),
      ).toContain('commit');
    });

    describe('Given commit title and author props', () => {
      it('should render a link to the author profile', () => {
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container').getAttribute('href'),
        ).toEqual(props.author.path);
      });

      it('Should render the author avatar with title and alt attributes', () => {
        expect(
          component.$el
            .querySelector('.commit-title .avatar-image-container .js-user-avatar-image-toolip')
            .textContent.trim(),
        ).toContain(props.author.username);

        expect(
          component.$el
            .querySelector('.commit-title .avatar-image-container img')
            .getAttribute('alt'),
        ).toContain(`${props.author.username}'s avatar`);
      });
    });

    it('should render the commit title', () => {
      expect(component.$el.querySelector('a.commit-row-message').getAttribute('href')).toEqual(
        props.commitUrl,
      );

      expect(component.$el.querySelector('a.commit-row-message').textContent).toContain(
        props.title,
      );
    });
  });

  describe('When commit title is not provided', () => {
    it('should render default message', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      component = mountComponent(CommitComponent, props);

      expect(component.$el.querySelector('.commit-title span').textContent).toContain(
        "Can't find HEAD commit for this branch",
      );
    });
  });

  describe('When commit ref is provided, but merge ref is not', () => {
    it('should render the commit ref', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      component = mountComponent(CommitComponent, props);
      const refEl = component.$el.querySelector('.ref-name');

      expect(refEl.textContent).toContain('master');

      expect(refEl.href).toBe(props.commitRef.ref_url);

      expect(refEl.getAttribute('data-original-title')).toBe(props.commitRef.name);

      expect(component.$el.querySelector('.icon-container .ic-branch')).not.toBeNull();
    });
  });

  describe('When both commit and merge ref are provided', () => {
    it('should render the merge ref', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        mergeRequestRef: {
          iid: 1234,
          path: 'https://example.com/path/to/mr',
          title: 'Test MR',
        },
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      component = mountComponent(CommitComponent, props);
      const refEl = component.$el.querySelector('.ref-name');

      expect(refEl.textContent).toContain('1234');

      expect(refEl.href).toBe(props.mergeRequestRef.path);

      expect(refEl.getAttribute('data-original-title')).toBe(props.mergeRequestRef.title);

      expect(component.$el.querySelector('.icon-container .ic-git-merge')).not.toBeNull();
    });
  });

  describe('When showRefInfo === false', () => {
    it('should not render any ref info', () => {
      props = {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl:
          'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        mergeRequestRef: {
          iid: 1234,
          path: '/path/to/mr',
          title: 'Test MR',
        },
        shortSha: 'b7836edd',
        title: null,
        author: {},
        showRefInfo: false,
      };

      component = mountComponent(CommitComponent, props);

      expect(component.$el.querySelector('.ref-name')).toBeNull();
    });
  });
});
