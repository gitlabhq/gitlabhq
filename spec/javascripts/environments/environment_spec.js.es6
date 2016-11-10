//= require vue
//= require environments/stores/environments_store
//= require environments/components/environment

/* globals environmentsList */
describe('Environments', () => {
  fixture.preload('environments/environments.html');
  fixture.preload('environments/environments_no_permission.html');
  let Store;
  let component;

  beforeEach(() => {
    Store = window.gl.environmentsList.EnvironmentsStore;
  });

  describe('While loading', () => {
    beforeEach(() => {
      fixture.load('environments/environments.html');
      component = new window.gl.environmentsList.EnvironmentsComponent({
        el: document.querySelector('#environments-list-view'),
        propsData: {
          store: Store.create(),
        },
      });
    });

    it('Should render two tabs', () => {
      expect(component.$el.querySelectorAll('ul li').length).toEqual(2);
    });

    it('Should render bagdes with zeros in both tabs indicating the number of available environments', () => {
      expect(
        component.$el.querySelector('.js-available-environments-count').textContent
      ).toContain('0');
      expect(
        component.$el.querySelector('.js-stopped-environments-count').textContent
      ).toContain('0');
    });

    it('Should render loading icon', () => {
      expect(
        component.$el.querySelector('environments-list-loading')
      ).toBeDefined();
    });
  });

  describe('Without environments', () => {
    beforeEach(() => {
      fixture.load('environments/environments.html');

      spyOn(component, 'ready').and.callFake(() => {
        return {
          then: callback => callback([]),
          json: () => ({ then: cb => cb([]) }),
        };
      });

      component = new window.gl.environmentsList.EnvironmentsComponent({
        el: document.querySelector('#environments-list-view'),
        propsData: {
          store: Store.create(),
        },
      });
    });

    it('Should render two tabs', () => {
      expect(component.$el.querySelectorAll('ul li').length).toEqual(2);
    });

    it('Should render bagdes with zeros in both tabs indicating the number of available environments', () => {
      expect(
        component.$el.querySelector('.js-available-environments-count').textContent
      ).toContain('0');
      expect(
        component.$el.querySelector('.js-stopped-environments-count').textContent
      ).toContain('0');
    });

    it('Should render blank state information', () => {
      expect(
        component.$el.querySelector('.blank-state-title').textContent
      ).toEqual('You don\'t have any environments right now.');

      expect(
        component.$el.querySelector('.blank-state-text').textContent
      ).toEqual('Environments are places where code gets deployed, such as staging or production.');
    });

    it('Should render the provided help url', () => {
      expect(
        component.$el.querySelector('.blank-state a').getAttribute('href')
      ).toEqual(component.$data.helpPagePath);
    });

    describe('With create permission', () => {
      it('Should render new environment button', () => {
        expect(
          component.$el.querySelector('a.btn-create').getAttribute('href')
        ).toEqual(component.$data.newEnvironmentPath);
        expect(
          component.$el.querySelector('a.btn-create').textContent
        ).toEqual('New environment');
      });
    });

    describe('Without create permission', () => {
      beforeEach('Load fixture without permission', () => {
        fixture.load('environments/environments_no_permission.html');
        component = new window.gl.environmentsList.EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
          propsData: {
            store: Store.create(),
          },
        });
      });

      it('Should not render new environment button', () => {

      });
    });
  });

  describe('With environments', () => {
    describe('Tabs behavior', () => {
      it('Should render two tabs', () => {

      });

      it('Should render badges with the correct count', () => {

      });

      describe('When clicking in the available tab', () => {
        it('Should make Available tab active', () => {

        });

        it('Should make visible only available environments', () => {

        });
      });

      describe('When clicking in the stopped tab', () => {
        it('Should make Stopped tab active', () => {

        });

        it('Should make visible only stopped environments', () => {

        });
      });
    });

    describe('With create permissions', () => {
      it('Should render new environment button', () => {

      });
    });

    describe('Without create permissions', () => {
      it('Should not render the new environment button', () => {
      });
    });

    it('Should render a table', () => {
    });

    it('Should render table pagination', () => {

    });
  });
});
