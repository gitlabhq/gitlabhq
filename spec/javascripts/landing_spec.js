import Cookies from 'js-cookie';
import Landing from '~/landing';

describe('Landing', function() {
  describe('class constructor', function() {
    beforeEach(function() {
      this.landingElement = {};
      this.dismissButton = {};
      this.cookieName = 'cookie_name';

      this.landing = new Landing(this.landingElement, this.dismissButton, this.cookieName);
    });

    it('should set .landing', function() {
      expect(this.landing.landingElement).toBe(this.landingElement);
    });

    it('should set .cookieName', function() {
      expect(this.landing.cookieName).toBe(this.cookieName);
    });

    it('should set .dismissButton', function() {
      expect(this.landing.dismissButton).toBe(this.dismissButton);
    });

    it('should set .eventWrapper', function() {
      expect(this.landing.eventWrapper).toEqual({});
    });
  });

  describe('toggle', function() {
    beforeEach(function() {
      this.isDismissed = false;
      this.landingElement = { classList: jasmine.createSpyObj('classList', ['toggle']) };
      this.landing = {
        isDismissed: () => {},
        addEvents: () => {},
        landingElement: this.landingElement,
      };

      spyOn(this.landing, 'isDismissed').and.returnValue(this.isDismissed);
      spyOn(this.landing, 'addEvents');

      Landing.prototype.toggle.call(this.landing);
    });

    it('should call .isDismissed', function() {
      expect(this.landing.isDismissed).toHaveBeenCalled();
    });

    it('should call .classList.toggle', function() {
      expect(this.landingElement.classList.toggle).toHaveBeenCalledWith('hidden', this.isDismissed);
    });

    it('should call .addEvents', function() {
      expect(this.landing.addEvents).toHaveBeenCalled();
    });

    describe('if isDismissed is true', function() {
      beforeEach(function() {
        this.isDismissed = true;
        this.landingElement = { classList: jasmine.createSpyObj('classList', ['toggle']) };
        this.landing = {
          isDismissed: () => {},
          addEvents: () => {},
          landingElement: this.landingElement,
        };

        spyOn(this.landing, 'isDismissed').and.returnValue(this.isDismissed);
        spyOn(this.landing, 'addEvents');

        this.landing.isDismissed.calls.reset();

        Landing.prototype.toggle.call(this.landing);
      });

      it('should not call .addEvents', function() {
        expect(this.landing.addEvents).not.toHaveBeenCalled();
      });
    });
  });

  describe('addEvents', function() {
    beforeEach(function() {
      this.dismissButton = jasmine.createSpyObj('dismissButton', ['addEventListener']);
      this.eventWrapper = {};
      this.landing = {
        eventWrapper: this.eventWrapper,
        dismissButton: this.dismissButton,
        dismissLanding: () => {},
      };

      Landing.prototype.addEvents.call(this.landing);
    });

    it('should set .eventWrapper.dismissLanding', function() {
      expect(this.eventWrapper.dismissLanding).toEqual(jasmine.any(Function));
    });

    it('should call .addEventListener', function() {
      expect(this.dismissButton.addEventListener).toHaveBeenCalledWith(
        'click',
        this.eventWrapper.dismissLanding,
      );
    });
  });

  describe('removeEvents', function() {
    beforeEach(function() {
      this.dismissButton = jasmine.createSpyObj('dismissButton', ['removeEventListener']);
      this.eventWrapper = { dismissLanding: () => {} };
      this.landing = {
        eventWrapper: this.eventWrapper,
        dismissButton: this.dismissButton,
      };

      Landing.prototype.removeEvents.call(this.landing);
    });

    it('should call .removeEventListener', function() {
      expect(this.dismissButton.removeEventListener).toHaveBeenCalledWith(
        'click',
        this.eventWrapper.dismissLanding,
      );
    });
  });

  describe('dismissLanding', function() {
    beforeEach(function() {
      this.landingElement = { classList: jasmine.createSpyObj('classList', ['add']) };
      this.cookieName = 'cookie_name';
      this.landing = { landingElement: this.landingElement, cookieName: this.cookieName };

      spyOn(Cookies, 'set');

      Landing.prototype.dismissLanding.call(this.landing);
    });

    it('should call .classList.add', function() {
      expect(this.landingElement.classList.add).toHaveBeenCalledWith('hidden');
    });

    it('should call Cookies.set', function() {
      expect(Cookies.set).toHaveBeenCalledWith(this.cookieName, 'true', { expires: 365 });
    });
  });

  describe('isDismissed', function() {
    beforeEach(function() {
      this.cookieName = 'cookie_name';
      this.landing = { cookieName: this.cookieName };

      spyOn(Cookies, 'get').and.returnValue('true');

      this.isDismissed = Landing.prototype.isDismissed.call(this.landing);
    });

    it('should call Cookies.get', function() {
      expect(Cookies.get).toHaveBeenCalledWith(this.cookieName);
    });

    it('should return a boolean', function() {
      expect(typeof this.isDismissed).toEqual('boolean');
    });
  });
});
