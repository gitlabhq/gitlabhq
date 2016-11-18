//= require vue
//= require environments/components/environment_item

describe('Environment item', () => {
  fixture.preload('environments/table.html');
  beforeEach(() => {
    fixture.load('environments/table.html');
  });

  describe('When item is folder', () => {
    let mockItem;
    let component;

    beforeEach(() => {
      mockItem = {
        name: 'review',
        children: [
          {
            name: 'review-app',
            id: 1,
            state: 'available',
            external_url: '',
            last_deployment: {},
            created_at: '2016-11-07T11:11:16.525Z',
            updated_at: '2016-11-10T15:55:58.778Z',
          },
          {
            name: 'production',
            id: 2,
            state: 'available',
            external_url: '',
            last_deployment: {},
            created_at: '2016-11-07T11:11:16.525Z',
            updated_at: '2016-11-10T15:55:58.778Z',
          },
        ],
      };

      component = new window.gl.environmentsList.EnvironmentItem({
        el: document.querySelector('tr#environment-row'),
        propsData: {
          model: mockItem,
          toggleRow: () => {},
          canCreateDeployment: false,
          canReadEnvironment: true,
        },
      });
    });

    it('Should render folder icon and name', () => {
      expect(component.$el.querySelector('.folder-name').textContent).toContain(mockItem.name);
      expect(component.$el.querySelector('.folder-icon')).toBeDefined();
    });

    it('Should render the number of children in a badge', () => {
      expect(component.$el.querySelector('.folder-name .badge').textContent).toContain(mockItem.children.length);
    });
  });

  describe('when item is not folder', () => {
    let environment;
    let component;

    beforeEach(() => {
      environment = {
        id: 31,
        name: 'production',
        state: 'stopped',
        external_url: 'http://external.com',
        environment_type: null,
        last_deployment: {
          id: 66,
          iid: 6,
          sha: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
          ref: {
            name: 'master',
            ref_path: 'root/ci-folders/tree/master',
          },
          tag: true,
          'last?': true,
          user: {
            name: 'Administrator',
            username: 'root',
            id: 1,
            state: 'active',
            avatar_url: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
            web_url: 'http://localhost:3000/root',
          },
          commit: {
            id: '500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
            short_id: '500aabcb',
            title: 'Update .gitlab-ci.yml',
            author_name: 'Administrator',
            author_email: 'admin@example.com',
            created_at: '2016-11-07T18:28:13.000+00:00',
            message: 'Update .gitlab-ci.yml',
            author: {
              name: 'Administrator',
              username: 'root',
              id: 1,
              state: 'active',
              avatar_url: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
              web_url: 'http://localhost:3000/root',
            },
            commit_path: '/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
          },
          deployable: {
            id: 1279,
            name: 'deploy',
            build_path: '/root/ci-folders/builds/1279',
            retry_path: '/root/ci-folders/builds/1279/retry',
          },
          manual_actions: [
            {
              name: 'action',
              play_path: '/play',
            },
          ],
        },
        'stoppable?': true,
        environment_path: 'root/ci-folders/environments/31',
        created_at: '2016-11-07T11:11:16.525Z',
        updated_at: '2016-11-10T15:55:58.778Z',
      };

      component = new window.gl.environmentsList.EnvironmentItem({
        el: document.querySelector('tr#environment-row'),
        propsData: {
          model: environment,
          toggleRow: () => {},
          canCreateDeployment: true,
          canReadEnvironment: true,
        },
      });
    });

    it('should render environment name', () => {
      expect(component.$el.querySelector('.environment-name').textContent).toEqual(environment.name);
    });

    describe('With deployment', () => {
      it('should render deployment internal id', () => {
        expect(
          component.$el.querySelector('.deployment-column span').textContent
        ).toContain(environment.last_deployment.iid);

        expect(
          component.$el.querySelector('.deployment-column span').textContent
        ).toContain('#');
      });

      describe('With user information', () => {
        it('should render user avatar with link to profile', () => {
          expect(
            component.$el.querySelector('.js-deploy-user-container').getAttribute('href')
          ).toEqual(environment.last_deployment.user.web_url);
        });
      });

      describe('With build url', () => {
        it('Should link to build url provided', () => {
          expect(
            component.$el.querySelector('.build-link').getAttribute('href')
          ).toEqual(environment.last_deployment.deployable.build_path);
        });

        it('Should render deployable name and id', () => {
          expect(
            component.$el.querySelector('.build-link').getAttribute('href')
          ).toEqual(environment.last_deployment.deployable.build_path);
        });
      });

      describe('With commit information', () => {
        it('should render commit component', () => {
          expect(
            component.$el.querySelector('.js-commit-component')
          ).toBeDefined();
        });
      });
    });

    describe('With manual actions', () => {
      it('Should render actions component', () => {
        expect(
          component.$el.querySelector('.js-manual-actions-container')
        ).toBeDefined();
      });
    });

    describe('With external URL', () => {
      it('should render external url component', () => {
        expect(
          component.$el.querySelector('.js-external-url-container')
        ).toBeDefined();
      });
    });

    describe('With stop action', () => {
      it('Should render stop action component', () => {
        expect(
          component.$el.querySelector('.js-stop-component-container')
        ).toBeDefined();
      });
    });

    describe('With retry action', () => {
      it('Should render rollback component', () => {
        expect(
          component.$el.querySelector('.js-rollback-component-container')
        ).toBeDefined();
      });
    });
  });
});
