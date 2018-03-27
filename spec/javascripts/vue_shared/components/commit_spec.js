import Vue from 'vue';
import commitComp from '~/vue_shared/components/commit.vue';

describe('Commit component', () => {
  let props;
  let component;
  let CommitComponent;

  beforeEach(() => {
    CommitComponent = Vue.extend(commitComp);
  });

  it('should render a fork icon if it does not represent a tag', () => {
    component = new CommitComponent({
      propsData: {
        tag: false,
        commitRef: {
          name: 'master',
          ref_url: 'http://localhost/namespace2/gitlabhq/tree/master',
        },
        commitUrl: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: 'Commit message',
        author: {
          avatar_url: 'https://gitlab.com/uploads/-/system/user/avatar/300478/avatar.png',
          web_url: 'https://gitlab.com/jschatz1',
          path: '/jschatz1',
          username: 'jschatz1',
        },
      },
    }).$mount();

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
        commitUrl: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: 'Commit message',
        author: {
          avatar_url: 'https://gitlab.com/uploads/-/system/user/avatar/300478/avatar.png',
          web_url: 'https://gitlab.com/jschatz1',
          path: '/jschatz1',
          username: 'jschatz1',
        },
        commitIconSvg: '<svg></svg>',
      };

      component = new CommitComponent({
        propsData: props,
      }).$mount();
    });

    it('should render a tag icon if it represents a tag', () => {
      expect(component.$el.querySelector('.icon-container i').classList).toContain('fa-tag');
    });

    it('should render a link to the ref url', () => {
      expect(component.$el.querySelector('.ref-name').getAttribute('href')).toEqual(props.commitRef.ref_url);
    });

    it('should render the ref name', () => {
      expect(component.$el.querySelector('.ref-name').textContent).toContain(props.commitRef.name);
    });

    it('should render the commit short sha with a link to the commit url', () => {
      expect(component.$el.querySelector('.commit-sha').getAttribute('href')).toEqual(props.commitUrl);
      expect(component.$el.querySelector('.commit-sha').textContent).toContain(props.shortSha);
    });

    it('should render the given commitIconSvg', () => {
      expect(component.$el.querySelector('.js-commit-icon').children).toContain('svg');
    });

    describe('Given commit title and author props', () => {
      it('should render a link to the author profile', () => {
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container').getAttribute('href'),
        ).toEqual(props.author.path);
      });

      it('Should render the author avatar with title and alt attributes', () => {
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container img').getAttribute('data-original-title'),
        ).toContain(props.author.username);
        expect(
          component.$el.querySelector('.commit-title .avatar-image-container img').getAttribute('alt'),
        ).toContain(`${props.author.username}'s avatar`);
      });
    });

    it('should render the commit title', () => {
      expect(
        component.$el.querySelector('a.commit-row-message').getAttribute('href'),
      ).toEqual(props.commitUrl);
      expect(
        component.$el.querySelector('a.commit-row-message').textContent,
      ).toContain(props.title);
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
        commitUrl: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
        shortSha: 'b7836edd',
        title: null,
        author: {},
      };

      component = new CommitComponent({
        propsData: props,
      }).$mount();

      expect(
        component.$el.querySelector('.commit-title span').textContent,
      ).toContain('Cant find HEAD commit for this branch');
    });
  });
});
