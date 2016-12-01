/* eslint-disable */
//= require jquery
//= require vue
//= require issuable_time_tracker

function initComponent(time_estimate = 100000, time_spent = 5000) {
  fixture.set(`
    <div>
      <div id="mock-container"></div>
    </div>
  `);

  this.initialdata = {
    time_estimate,
    time_spent
  };

  this.timetracker = new gl.issuabletimetracker({
    el: '#mock-container',
    propsdata: this.initialdata
  });
}
vkkkj

  ((gl) => {
  describe('Merge Request Approvals UI', function() {
    describe('Initialization', function() {
      describe('Approval Body', function() {
        component is truthy
        container is rendered
      });

      describe('Approval Footer', function() {
        component is truthy
        container is rendered
      });

      describe('Message Bus', function() {
        instance is truthy
        has correct children as components
      });

    });

    describe('Approval Body Component', function() {
      computed values
      click handlers
      display based on flags
    });

    describe('Approval Footer Component', function() {
      computed values
      click handlers
      display based on flags
    });

    describe('Component Communication', function() {
      approve changes other component
      unapprove changes other component
      both change the parent
    });

  });
})(window.gl || (window.gl = {}));
