import _ from 'underscore';
import Vue from 'vue';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMoveIssue from '~/sidebar/lib/sidebar_move_issue';
import Mock from './mock_data';

describe('SidebarMoveIssue', () => {
  beforeEach(() => {
    Vue.http.interceptors.push(Mock.sidebarMockInterceptor);
    this.mediator = new SidebarMediator(Mock.mediator);
    this.$content = $(`
      <div class="dropdown">
        <div class="js-toggle"></div>
        <div class="dropdown-content"></div>
        <div class="js-confirm-button"></div>
      </div>
    `);
    this.$toggleButton = this.$content.find('.js-toggle');
    this.$confirmButton = this.$content.find('.js-confirm-button');

    this.sidebarMoveIssue = new SidebarMoveIssue(
      this.mediator,
      this.$toggleButton,
      this.$confirmButton,
    );
    this.sidebarMoveIssue.init();
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;

    this.sidebarMoveIssue.destroy();

    Vue.http.interceptors = _.without(Vue.http.interceptors, Mock.sidebarMockInterceptor);
  });

  describe('init', () => {
    it('should initialize the dropdown and listeners', () => {
      spyOn(this.sidebarMoveIssue, 'initDropdown');
      spyOn(this.sidebarMoveIssue, 'addEventListeners');

      this.sidebarMoveIssue.init();

      expect(this.sidebarMoveIssue.initDropdown).toHaveBeenCalled();
      expect(this.sidebarMoveIssue.addEventListeners).toHaveBeenCalled();
    });
  });

  describe('destroy', () => {
    it('should remove the listeners', () => {
      spyOn(this.sidebarMoveIssue, 'removeEventListeners');

      this.sidebarMoveIssue.destroy();

      expect(this.sidebarMoveIssue.removeEventListeners).toHaveBeenCalled();
    });
  });

  describe('initDropdown', () => {
    it('should initialize the gl_dropdown', () => {
      spyOn($.fn, 'glDropdown');

      this.sidebarMoveIssue.initDropdown();

      expect($.fn.glDropdown).toHaveBeenCalled();
    });

    it('escapes html from project name', (done) => {
      this.$toggleButton.dropdown('toggle');

      setTimeout(() => {
        expect(this.$content.find('.js-move-issue-dropdown-item')[1].innerHTML.trim()).toEqual('&lt;img src=x onerror=alert(document.domain)&gt; foo / bar');
        done();
      });
    });
  });

  describe('onConfirmClicked', () => {
    it('should move the issue with valid project ID', () => {
      spyOn(this.mediator, 'moveIssue').and.returnValue(Promise.resolve());
      this.mediator.setMoveToProjectId(7);

      this.sidebarMoveIssue.onConfirmClicked();

      expect(this.mediator.moveIssue).toHaveBeenCalled();
      expect(this.$confirmButton.attr('disabled')).toBe('disabled');
      expect(this.$confirmButton.hasClass('is-loading')).toBe(true);
    });

    it('should remove loading state from confirm button on failure', (done) => {
      spyOn(window, 'Flash');
      spyOn(this.mediator, 'moveIssue').and.returnValue(Promise.reject());
      this.mediator.setMoveToProjectId(7);

      this.sidebarMoveIssue.onConfirmClicked();

      expect(this.mediator.moveIssue).toHaveBeenCalled();
      // Wait for the move issue request to fail
      setTimeout(() => {
        expect(window.Flash).toHaveBeenCalled();
        expect(this.$confirmButton.attr('disabled')).toBe(undefined);
        expect(this.$confirmButton.hasClass('is-loading')).toBe(false);
        done();
      });
    });

    it('should not move the issue with id=0', () => {
      spyOn(this.mediator, 'moveIssue');
      this.mediator.setMoveToProjectId(0);

      this.sidebarMoveIssue.onConfirmClicked();

      expect(this.mediator.moveIssue).not.toHaveBeenCalled();
    });
  });

  it('should set moveToProjectId on dropdown item "No project" click', (done) => {
    spyOn(this.mediator, 'setMoveToProjectId');

    // Open the dropdown
    this.$toggleButton.dropdown('toggle');

    // Wait for the autocomplete request to finish
    setTimeout(() => {
      this.$content.find('.js-move-issue-dropdown-item').eq(0).trigger('click');

      expect(this.mediator.setMoveToProjectId).toHaveBeenCalledWith(0);
      expect(this.$confirmButton.attr('disabled')).toBe('disabled');
      done();
    }, 0);
  });

  it('should set moveToProjectId on dropdown item click', (done) => {
    spyOn(this.mediator, 'setMoveToProjectId');

    // Open the dropdown
    this.$toggleButton.dropdown('toggle');

    // Wait for the autocomplete request to finish
    setTimeout(() => {
      this.$content.find('.js-move-issue-dropdown-item').eq(1).trigger('click');

      expect(this.mediator.setMoveToProjectId).toHaveBeenCalledWith(20);
      expect(this.$confirmButton.attr('disabled')).toBe(undefined);
      done();
    }, 0);
  });
});
