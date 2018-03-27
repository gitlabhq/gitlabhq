import 'timeago.js';
import Vue from 'vue';
import environmentItemComp from '~/environments/components/environment_item.vue';

describe('Environment item', () => {
  let EnvironmentItem;

  beforeEach(() => {
    EnvironmentItem = Vue.extend(environmentItemComp);
  });

  describe('When item is folder', () => {
    let mockItem;
    let component;

    beforeEach(() => {
      mockItem = {
        name: 'review',
        folderName: 'review',
        size: 3,
        isFolder: true,
        environment_path: 'url',
      };

      component = new EnvironmentItem({
        propsData: {
          model: mockItem,
          canCreateDeployment: false,
          canReadEnvironment: true,
          service: {},
        },
      }).$mount();
    });

    it('Should render folder icon and name', () => {
      expect(component.$el.querySelector('.folder-name').textContent).toContain(mockItem.name);
      expect(component.$el.querySelector('.folder-icon')).toBeDefined();
    });

    it('Should render the number of children in a badge', () => {
      expect(component.$el.querySelector('.folder-name .badge').textContent).toContain(mockItem.size);
    });
  });

  describe('when item is not folder', () => {
    let environment;
    let component;

    beforeEach(() => {
      environment = {
        name: 'production',
        size: 1,
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
            avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
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
              avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
              web_url: 'http://localhost:3000/root',
            },
            commit_path: '/root/ci-folders/tree/500aabcb17c97bdcf2d0c410b70cb8556f0362dd',
          },
          deployable: {
            id: 1279,
            name: 'deploy',
            build_path: '/root/ci-folders/builds/1279',
            retry_path: '/root/ci-folders/builds/1279/retry',
            created_at: '2016-11-29T18:11:58.430Z',
            updated_at: '2016-11-29T18:11:58.430Z',
          },
          manual_actions: [
            {
              name: 'action',
              play_path: '/play',
            },
          ],
        },
        'stop_action?': true,
        environment_path: 'root/ci-folders/environments/31',
        created_at: '2016-11-07T11:11:16.525Z',
        updated_at: '2016-11-10T15:55:58.778Z',
      };

      component = new EnvironmentItem({
        propsData: {
          model: environment,
          canCreateDeployment: true,
          canReadEnvironment: true,
          service: {},
        },
      }).$mount();
    });

    it('should render environment name', () => {
      expect(component.$el.querySelector('.environment-name').textContent).toContain(environment.name);
    });

    describe('With deployment', () => {
      it('should render deployment internal id', () => {
        expect(
          component.$el.querySelector('.deployment-column span').textContent,
        ).toContain(environment.last_deployment.iid);

        expect(
          component.$el.querySelector('.deployment-column span').textContent,
        ).toContain('#');
      });

      it('should render last deployment date', () => {
        const timeagoInstance = new timeago(); // eslint-disable-line
        const formatedDate = timeagoInstance.format(
          environment.last_deployment.deployable.created_at,
        );

        expect(
          component.$el.querySelector('.environment-created-date-timeago').textContent,
        ).toContain(formatedDate);
      });

      describe('With user information', () => {
        it('should render user avatar with link to profile', () => {
          expect(
            component.$el.querySelector('.js-deploy-user-container').getAttribute('href'),
          ).toEqual(environment.last_deployment.user.web_url);
        });
      });

      describe('With build url', () => {
        it('Should link to build url provided', () => {
          expect(
            component.$el.querySelector('.build-link').getAttribute('href'),
          ).toEqual(environment.last_deployment.deployable.build_path);
        });

        it('Should render deployable name and id', () => {
          expect(
            component.$el.querySelector('.build-link').getAttribute('href'),
          ).toEqual(environment.last_deployment.deployable.build_path);
        });
      });

      describe('With commit information', () => {
        it('should render commit component', () => {
          expect(
            component.$el.querySelector('.js-commit-component'),
          ).toBeDefined();
        });
      });
    });

    describe('With manual actions', () => {
      it('Should render actions component', () => {
        expect(
          component.$el.querySelector('.js-manual-actions-container'),
        ).toBeDefined();
      });
    });

    describe('With external URL', () => {
      it('should render external url component', () => {
        expect(
          component.$el.querySelector('.js-external-url-container'),
        ).toBeDefined();
      });
    });

    describe('With stop action', () => {
      it('Should render stop action component', () => {
        expect(
          component.$el.querySelector('.js-stop-component-container'),
        ).toBeDefined();
      });
    });

    describe('With retry action', () => {
      it('Should render rollback component', () => {
        expect(
          component.$el.querySelector('.js-rollback-component-container'),
        ).toBeDefined();
      });
    });
  });
});
