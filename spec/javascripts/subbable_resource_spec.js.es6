/* eslint-disable */
//= require jquery
//= require smart_interval
//= require subbable_resource

((global) => {
  describe('Subbable Resource', function () {
    describe('PubSub', function () {
      beforeEach(function () {
        fixture.set('<div></div>');
        const resourcePath = 'http://example.com';
        const pollingConfig = { startingInterval: 10, maxInterval: 1000, lazyStart: true };

        this.MockResource = global.createSubbableResource({ resourcePath, pollingConfig });
        this.state = { propOne: 'propOne', propTwo: 'propTwo' };
      });

      it('should successfully add multiple subscribers', function () {
        const SUBSCRIBERS_COUNT = 5;

        for (let i = 0; i < SUBSCRIBERS_COUNT; i += 1) {
          this.MockResource.subscribe(() => {});
        }

        expect(this.MockResource.subscribers.length).toBe(SUBSCRIBERS_COUNT);
      });

      it('should successfully publish an update to a subscriber', function () {
        const propOneRevised = 'propOneRevised';

        function subscribeCallback(state) {
          expect(state.propOne).toBe(propOneRevised);
          expect(state.propTwo).toBe('propTwo');
        }

        this.MockResource.subscribe(subscribeCallback);

        this.state.propOne = propOneRevised;

        this.MockResource.publish(this.state);
      });
    });
  });
})(window.gl || (window.gl = {}));
