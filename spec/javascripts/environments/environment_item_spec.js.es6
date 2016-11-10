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
          'can-create-deployment': false,
          'can-read-environment': true,
        },
      });
    });

    it('Should render clickable folder icon and name', () => {
      expect(document.querySelector('.folder-name').textContent).toContain(mockItem.name);
      expect(document.querySelector('.folder-icon')).toBeDefined();
    });

    it('Should render the number of children in a badge', () => {
      expect(document.querySelector('.folder-name .badge').textContent).toContain(mockItem.children.length);
    });

    it('Should not render any information other than the name', () => {
    });

    describe('when clicked', () => {
      it('Should render child row', () => {
      });
    });
  });

  describe('when item is not folder', () => {
    it('should render environment name', () => {

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
