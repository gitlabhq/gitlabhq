import flash, {
  createFlashEl,
  createAction,
  hideFlash,
  removeFlashClickListener,
} from '~/flash';

describe('Flash', () => {
  describe('createFlashEl', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
    });

    afterEach(() => {
      el.innerHTML = '';
    });

    it('creates flash element with type', () => {
      el.innerHTML = createFlashEl('testing', 'alert');

      expect(
        el.querySelector('.flash-alert'),
      ).not.toBeNull();
    });

    it('escapes text', () => {
      el.innerHTML = createFlashEl('<script>alert("a");</script>', 'alert');

      expect(
        el.querySelector('.flash-text').textContent.trim(),
      ).toBe('<script>alert("a");</script>');
    });

    it('adds container classes when inside content wrapper', () => {
      el.innerHTML = createFlashEl('testing', 'alert', true);

      expect(
        el.querySelector('.flash-text').classList.contains('container-fluid'),
      ).toBeTruthy();
      expect(
        el.querySelector('.flash-text').classList.contains('container-limited'),
      ).toBeTruthy();
    });
  });

  describe('hideFlash', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
      el.className = 'js-testing';
    });

    it('sets transition style', () => {
      hideFlash(el);

      expect(
        el.style.transition,
      ).toBe('opacity 0.3s');
    });

    it('sets opacity style', () => {
      hideFlash(el);

      expect(
        el.style.opacity,
      ).toBe('0');
    });

    it('does not set styles when fadeTransition is false', () => {
      hideFlash(el, false);

      expect(
        el.style.opacity,
      ).toBe('');
      expect(
        el.style.transition,
      ).toBe('');
    });

    it('removes element after transitionend', () => {
      document.body.appendChild(el);

      hideFlash(el);
      el.dispatchEvent(new Event('transitionend'));

      expect(
        document.querySelector('.js-testing'),
      ).toBeNull();
    });

    it('calls event listener callback once', () => {
      spyOn(el, 'remove').and.callThrough();
      document.body.appendChild(el);

      hideFlash(el);

      el.dispatchEvent(new Event('transitionend'));
      el.dispatchEvent(new Event('transitionend'));

      expect(
        el.remove.calls.count(),
      ).toBe(1);
    });
  });

  describe('createAction', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
    });

    it('creates link with href', () => {
      el.innerHTML = createAction({
        href: 'testing',
        title: 'test',
      });

      expect(
        el.querySelector('.flash-action').href,
      ).toContain('testing');
    });

    it('uses hash as href when no href is present', () => {
      el.innerHTML = createAction({
        title: 'test',
      });

      expect(
        el.querySelector('.flash-action').href,
      ).toContain('#');
    });

    it('adds role when no href is present', () => {
      el.innerHTML = createAction({
        title: 'test',
      });

      expect(
        el.querySelector('.flash-action').getAttribute('role'),
      ).toBe('button');
    });

    it('escapes the title text', () => {
      el.innerHTML = createAction({
        title: '<script>alert("a")</script>',
      });

      expect(
        el.querySelector('.flash-action').textContent.trim(),
      ).toBe('<script>alert("a")</script>');
    });
  });

  describe('createFlash', () => {
    describe('no flash-container', () => {
      it('does not add to the DOM', () => {
        const flashEl = flash('testing');

        expect(
          flashEl,
        ).toBeNull();
        expect(
          document.querySelector('.flash-alert'),
        ).toBeNull();
      });
    });

    describe('with flash-container', () => {
      beforeEach(() => {
        document.body.innerHTML += `
          <div class="content-wrapper js-content-wrapper">
            <div class="flash-container"></div>
          </div>
        `;
      });

      afterEach(() => {
        document.querySelector('.js-content-wrapper').remove();
      });

      it('adds flash element into container', () => {
        flash('test', 'alert', document, null, false, true);

        expect(
          document.querySelector('.flash-alert'),
        ).not.toBeNull();

        expect(
          document.body.className,
        ).toContain('flash-shown');
      });

      it('adds flash into specified parent', () => {
        flash(
          'test',
          'alert',
          document.querySelector('.content-wrapper'),
        );

        expect(
          document.querySelector('.content-wrapper .flash-alert'),
        ).not.toBeNull();
      });

      it('adds container classes when inside content-wrapper', () => {
        flash('test');

        expect(
          document.querySelector('.flash-text').className,
        ).toBe('flash-text container-fluid container-limited');
      });

      it('does not add container when outside of content-wrapper', () => {
        document.querySelector('.content-wrapper').className = 'js-content-wrapper';
        flash('test');

        expect(
          document.querySelector('.flash-text').className.trim(),
        ).toBe('flash-text');
      });

      it('removes element after clicking', () => {
        flash('test', 'alert', document, null, false, true);

        document.querySelector('.flash-alert').click();

        expect(
          document.querySelector('.flash-alert'),
        ).toBeNull();

        expect(
          document.body.className,
        ).not.toContain('flash-shown');
      });

      describe('with actionConfig', () => {
        it('adds action link', () => {
          flash(
            'test',
            'alert',
            document,
            {
              title: 'test',
            },
          );

          expect(
            document.querySelector('.flash-action'),
          ).not.toBeNull();
        });

        it('calls actionConfig clickHandler on click', () => {
          const actionConfig = {
            title: 'test',
            clickHandler: jasmine.createSpy('actionConfig'),
          };

          flash(
            'test',
            'alert',
            document,
            actionConfig,
          );

          document.querySelector('.flash-action').click();

          expect(
            actionConfig.clickHandler,
          ).toHaveBeenCalled();
        });
      });
    });
  });

  describe('removeFlashClickListener', () => {
    beforeEach(() => {
      document.body.innerHTML += '<div class="flash-container"><div class="flash"></div></div>';
    });

    it('removes global flash on click', (done) => {
      const flashEl = document.querySelector('.flash');

      removeFlashClickListener(flashEl, false);

      flashEl.click();

      setTimeout(() => {
        expect(document.querySelector('.flash')).toBeNull();

        done();
      });
    });
  });
});
