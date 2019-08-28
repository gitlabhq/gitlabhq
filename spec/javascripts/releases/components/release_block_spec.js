import Vue from 'vue';
import component from '~/releases/components/release_block.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Release block', () => {
  const Component = Vue.extend(component);

  const release = {
    name: 'Bionic Beaver',
    tag_name: '18.04',
    description: '## changelog\n\n* line 1\n* line2',
    description_html: '<div><h2>changelog</h2><ul><li>line1</li<li>line 2</li></ul></div>',
    author_name: 'Release bot',
    author_email: 'release-bot@example.com',
    released_at: '2012-05-28T05:00:00-07:00',
    author: {
      avatar_url: 'uploads/-/system/user/avatar/johndoe/avatar.png',
      id: 482476,
      name: 'John Doe',
      path: '/johndoe',
      state: 'active',
      status_tooltip_html: null,
      username: 'johndoe',
      web_url: 'https://gitlab.com/johndoe',
    },
    commit: {
      id: '2695effb5807a22ff3d138d593fd856244e155e7',
      short_id: '2695effb',
      title: 'Initial commit',
      created_at: '2017-07-26T11:08:53.000+02:00',
      parent_ids: ['2a4b78934375d7f53875269ffd4f45fd83a84ebe'],
      message: 'Initial commit',
      author_name: 'John Smith',
      author_email: 'john@example.com',
      authored_date: '2012-05-28T04:42:42-07:00',
      committer_name: 'Jack Smith',
      committer_email: 'jack@example.com',
      committed_date: '2012-05-28T04:42:42-07:00',
    },
    assets: {
      count: 6,
      sources: [
        {
          format: 'zip',
          url: 'https://gitlab.com/gitlab-org/gitlab-ce/-/archive/v11.3.12/gitlab-ce-v11.3.12.zip',
        },
        {
          format: 'tar.gz',
          url:
            'https://gitlab.com/gitlab-org/gitlab-ce/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.gz',
        },
        {
          format: 'tar.bz2',
          url:
            'https://gitlab.com/gitlab-org/gitlab-ce/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar.bz2',
        },
        {
          format: 'tar',
          url: 'https://gitlab.com/gitlab-org/gitlab-ce/-/archive/v11.3.12/gitlab-ce-v11.3.12.tar',
        },
      ],
      links: [
        {
          name: 'release-18.04.dmg',
          url: 'https://my-external-hosting.example.com/scrambled-url/',
          external: true,
        },
        {
          name: 'binary-linux-amd64',
          url:
            'https://gitlab.com/gitlab-org/gitlab-ce/-/jobs/artifacts/v11.6.0-rc4/download?job=rspec-mysql+41%2F50',
          external: false,
        },
      ],
    },
  };
  let vm;

  const factory = props => mountComponent(Component, { release: props });

  beforeEach(() => {
    vm = factory(release);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it("renders the block with an id equal to the release's tag name", () => {
    expect(vm.$el.id).toBe('18.04');
  });

  it('renders release name', () => {
    expect(vm.$el.textContent).toContain(release.name);
  });

  it('renders commit sha', () => {
    expect(vm.$el.textContent).toContain(release.commit.short_id);
  });

  it('renders tag name', () => {
    expect(vm.$el.textContent).toContain(release.tag_name);
  });

  it('renders release date', () => {
    expect(vm.$el.textContent).toContain(timeagoMixin.methods.timeFormated(release.released_at));
  });

  it('renders number of assets provided', () => {
    expect(vm.$el.querySelector('.js-assets-count').textContent).toContain(release.assets.count);
  });

  it('renders dropdown with the sources', () => {
    expect(vm.$el.querySelectorAll('.js-sources-dropdown li').length).toEqual(
      release.assets.sources.length,
    );

    expect(vm.$el.querySelector('.js-sources-dropdown li a').getAttribute('href')).toEqual(
      release.assets.sources[0].url,
    );

    expect(vm.$el.querySelector('.js-sources-dropdown li a').textContent).toContain(
      release.assets.sources[0].format,
    );
  });

  it('renders list with the links provided', () => {
    expect(vm.$el.querySelectorAll('.js-assets-list li').length).toEqual(
      release.assets.links.length,
    );

    expect(vm.$el.querySelector('.js-assets-list li a').getAttribute('href')).toEqual(
      release.assets.links[0].url,
    );

    expect(vm.$el.querySelector('.js-assets-list li a').textContent).toContain(
      release.assets.links[0].name,
    );
  });

  it('renders author avatar', () => {
    expect(vm.$el.querySelector('.user-avatar-link')).not.toBeNull();
  });

  describe('external label', () => {
    it('renders external label when link is external', () => {
      expect(vm.$el.querySelector('.js-assets-list li a').textContent).toContain('external source');
    });

    it('does not render external label when link is not external', () => {
      expect(vm.$el.querySelector('.js-assets-list li:nth-child(2) a').textContent).not.toContain(
        'external source',
      );
    });
  });

  describe('with upcoming_release flag', () => {
    beforeEach(() => {
      vm = factory(Object.assign({}, release, { upcoming_release: true }));
    });

    it('renders upcoming release badge', () => {
      expect(vm.$el.textContent).toContain('Upcoming Release');
    });
  });
});
