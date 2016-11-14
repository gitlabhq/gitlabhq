//= require vue
//= require environments/components/environment_item

describe('Environment item', () => {
  fixture.preload('environments/table.html');
  beforeEach(() => {
    fixture.load('environments/table.html');
  });

  describe('When item is folder', () => {
    let mockItem;

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
    });

    it('Should render clickable folder icon and name', () => {
      const component = new window.gl.environmentsList.EnvironmentItem({
        el: document.querySelector('tr#environment-row'),
        propsData: {
          model: mockItem,
          toggleRow: () => {},
          'can-create-deployment': false,
          'can-read-environment': true,
        },
      });

      expect(component.$el.querySelector('.folder-name').textContent).toContain(mockItem.name);
      expect(component.$el.querySelector('.folder-icon')).toBeDefined();
    });

    it('Should render the number of children in a badge', () => {
      const component = new window.gl.environmentsList.EnvironmentItem({
        el: document.querySelector('tr#environment-row'),
        propsData: {
          model: mockItem,
          toggleRow: () => {},
          'can-create-deployment': false,
          'can-read-environment': true,
        },
      });

      expect(component.$el.querySelector('.folder-name .badge').textContent).toContain(mockItem.children.length);
    });

    describe('when clicked', () => {
      it('Should call the given prop', () => {
        const component = new window.gl.environmentsList.EnvironmentItem({
          el: document.querySelector('tr#environment-row'),
          propsData: {
            model: mockItem,
            toggleRow: () => {
              console.log('here!');
            },
            'can-create-deployment': false,
            'can-read-environment': true,
          },
        });

        spyOn(component.$options.propsData, 'toggleRow');
        component.$el.querySelector('.folder-name').click();

        expect(component.$options.propsData.toggleRow).toHaveBeenCalled();
      });
    });
  });

  describe('when item is not folder', () => {
    let environment;

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
            ref_url: 'http://localhost:3000/root/ci-folders/tree/master',
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
            commit_url: 'http://localhost:3000/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
          },
          deployable: {
            id: 1279,
            name: 'deploy',
            build_url: 'http://localhost:3000/root/ci-folders/builds/1279',
            retry_url: 'http://localhost:3000/root/ci-folders/builds/1279/retry',
          },
          manual_actions: [
            {
              name: 'action',
              play_url: 'http://localhost:3000/play',
            },
          ],
        },
        'stoppable?': true,
        environment_url: 'http://localhost:3000/root/ci-folders/environments/31',
        created_at: '2016-11-07T11:11:16.525Z',
        updated_at: '2016-11-10T15:55:58.778Z',
      };
    });

    it('should render environment name', () => {
      const component = new window.gl.environmentsList.EnvironmentItem({
        el: document.querySelector('tr#environment-row'),
        propsData: {
          model: environment,
          toggleRow: () => {},
          'can-create-deployment': false,
          'can-read-environment': true,
        },
      });

      debugger;
    });

    describe('With deployment', () => {
      it('should render deployment internal id', () => {

      });

      it('should link to deployment', () => {

      });

      describe('With user information', () => {
        it('should render user avatar with link to profile', () => {

        });
      });

      describe('With build url', () => {
        it('Should link to build url provided', () => {

        });

        it('Should render deployable name and id', () => {

        });
      });

      describe('With commit information', () => {
        it('should render commit component', () => {});
      });

      it('Should render timeago created date', () => {

      });
    });

    describe('Without deployment', () => {
      it('should render no deployments information', () => {

      });
    });

    describe('With manual actions', () => {
      describe('With create deployment permission', () => {
        it('Should render actions component', () => {

        });
      });
      describe('Without create deployment permission', () => {
        it('should not render actions component', () => {

        });
      });
    });

    describe('With external URL', () => {
      it('should render external url component', () => {

      });
    });

    describe('With stop action', () => {
      describe('With create deployment permission', () => {
        it('Should render stop action component', () => {

        });
      });
      describe('Without create deployment permission', () => {
        it('should not render stop action component', () => {

        });
      });
    });

    describe('With retry action', () => {
      describe('With create deployment permission', () => {
        it('Should render rollback component', () => {

        });
      });
      describe('Without create deployment permission', () => {
        it('should not render rollback component', () => {

        });
      });
    });
  });
});
