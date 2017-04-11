import Spinner from '~/spinner';
import ClassSpecHelper from './helpers/class_spec_helper';

describe('Spinner', () => {
  let renderable;
  let container;
  let spinner;

  describe('class constructor', () => {
    beforeEach(() => {
      renderable = {};
      container = {};

      spyOn(Spinner, 'createContainer').and.returnValue(container);

      spinner = new Spinner(renderable);
    });

    it('should set .renderable', () => {
      expect(spinner.renderable).toBe(renderable);
    });

    it('should call Spinner.createContainer', () => {
      expect(Spinner.createContainer).toHaveBeenCalled();
    });

    it('should set .container', () => {
      expect(spinner.container).toBe(container);
    });
  });

  describe('start', () => {
    beforeEach(() => {
      renderable = jasmine.createSpyObj('renderable', ['appendChild']);
      container = {};

      spinner = {
        renderable,
        container,
      };

      Spinner.prototype.start.call(spinner);
    });

    it('should set .innerHTML to an empty string', () => {
      expect(renderable.innerHTML).toEqual('');
    });

    it('should call .appendChild', () => {
      expect(renderable.appendChild).toHaveBeenCalledWith(container);
    });
  });

  describe('stop', () => {
    beforeEach(() => {
      container = jasmine.createSpyObj('container', ['remove']);

      spinner = {
        container,
      };

      Spinner.prototype.stop.call(spinner);
    });

    it('should call .remove', () => {
      expect(container.remove).toHaveBeenCalled();
    });
  });

  describe('createContainer', () => {
    let createContainer;

    beforeEach(() => {
      container = {
        classList: jasmine.createSpyObj('classList', ['add']),
      };

      spyOn(document, 'createElement').and.returnValue(container);

      createContainer = Spinner.createContainer();
    });

    ClassSpecHelper.itShouldBeAStaticMethod(Spinner, 'createContainer');

    it('should call document.createElement', () => {
      expect(document.createElement).toHaveBeenCalledWith('div');
    });

    it('should call classList.add', () => {
      expect(container.classList.add).toHaveBeenCalledWith('loading');
    });

    it('should return the container element', () => {
      expect(createContainer).toBe(container);
    });

    it('should set the container .innerHTML to Spinner.TEMPLATE', () => {
      expect(container.innerHTML).toBe(Spinner.TEMPLATE);
    });
  });
});
