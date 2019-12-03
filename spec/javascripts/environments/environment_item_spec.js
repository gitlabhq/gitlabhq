import { format } from 'timeago.js';
import Vue from 'vue';
import environmentItemComp from '~/environments/components/environment_item.vue';

const tableData = {
  name: {
    title: 'Environment',
    spacing: 'section-15',
  },
  deploy: {
    title: 'Deployment',
    spacing: 'section-10',
  },
  build: {
    title: 'Job',
    spacing: 'section-15',
  },
  commit: {
    title: 'Commit',
    spacing: 'section-20',
  },
  date: {
    title: 'Updated',
    spacing: 'section-10',
  },
  actions: {
    spacing: 'section-25',
  },
};

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
        log_path: 'url',
      };

      component = new EnvironmentItem({
        propsData: {
          model: mockItem,
          canReadEnvironment: true,
          tableData,
        },
      }).$mount();
    });

    it('should render folder icon and name', () => {
      expect(component.$el.querySelector('.folder-name').textContent).toContain(mockItem.name);
      expect(component.$el.querySelector('.folder-icon')).toBeDefined();
    });

    it('should render the number of children in a badge', () => {
      expect(component.$el.querySelector('.folder-name .badge').textContent).toContain(
        mockItem.size,
      );
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
            ref_url: 'root/ci-folders/tree/master',
          },
          tag: true,
          'last?': true,
          user: {
            name: 'Administrator',
            username: 'root',
            id: 1,
            state: 'active',
            avatar_url:
              'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
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
              avatar_url:
                'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon',
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
          deployed_at: '2016-11-29T18:11:58.430Z',
        },
        has_stop_action: true,
        environment_path: 'root/ci-folders/environments/31',
        log_path: 'root/ci-folders/environments/31/logs',
        created_at: '2016-11-07T11:11:16.525Z',
        updated_at: '2016-11-10T15:55:58.778Z',
      };

      component = new EnvironmentItem({
        propsData: {
          model: environment,
          canReadEnvironment: true,
          tableData,
        },
      }).$mount();
    });

    it('should render environment name', () => {
      expect(component.$el.querySelector('.environment-name').textContent).toContain(
        environment.name,
      );
    });

    describe('With deployment', () => {
      it('should render deployment internal id', () => {
        expect(component.$el.querySelector('.deployment-column span').textContent).toContain(
          environment.last_deployment.iid,
        );

        expect(component.$el.querySelector('.deployment-column span').textContent).toContain('#');
      });

      it('should render last deployment date', () => {
        const formatedDate = format(environment.last_deployment.deployed_at);

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
        it('should link to build url provided', () => {
          expect(component.$el.querySelector('.build-link').getAttribute('href')).toEqual(
            environment.last_deployment.deployable.build_path,
          );
        });

        it('should render deployable name and id', () => {
          expect(component.$el.querySelector('.build-link').getAttribute('href')).toEqual(
            environment.last_deployment.deployable.build_path,
          );
        });
      });

      describe('With commit information', () => {
        it('should render commit component', () => {
          expect(component.$el.querySelector('.js-commit-component')).toBeDefined();
        });
      });
    });

    describe('With manual actions', () => {
      it('should render actions component', () => {
        expect(component.$el.querySelector('.js-manual-actions-container')).toBeDefined();
      });
    });

    describe('With external URL', () => {
      it('should render external url component', () => {
        expect(component.$el.querySelector('.js-external-url-container')).toBeDefined();
      });
    });

    describe('With stop action', () => {
      it('should render stop action component', () => {
        expect(component.$el.querySelector('.js-stop-component-container')).toBeDefined();
      });
    });

    describe('With retry action', () => {
      it('should render rollback component', () => {
        expect(component.$el.querySelector('.js-rollback-component-container')).toBeDefined();
      });
    });
  });
});
