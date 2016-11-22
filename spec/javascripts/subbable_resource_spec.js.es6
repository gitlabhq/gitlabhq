/* eslint-disable */
//= vue
//= vue-resource
//= require jquery
//= require subbable_resource

/*
* Test that each rest verb calls the publish and subscribe function and passes the correct value back
*
*
* */
((global) => {
  describe('Subbable Resource', function () {
    describe('PubSub', function () {
      beforeEach(function () {
        this.MockResource = new global.SubbableResource('https://example.com');
      });
      it('should successfully add a single subscriber', function () {
        const callback = () => {};
        this.MockResource.subscribe(callback);

        expect(this.MockResource.subscribers.length).toBe(1);
        expect(this.MockResource.subscribers[0]).toBe(callback);
      });

      it('should successfully add multiple subscribers', function () {
        const callbackOne = () => {};
        const callbackTwo = () => {};
        const callbackThree = () => {};

        this.MockResource.subscribe(callbackOne);
        this.MockResource.subscribe(callbackTwo);
        this.MockResource.subscribe(callbackThree);

        expect(this.MockResource.subscribers.length).toBe(3);
      });

      it('should successfully publish an update to a single subscriber', function () {
        const state = { myprop: 1 };

        const callbacks = {
          one: (data) => expect(data.myprop).toBe(2),
          two: (data) => expect(data.myprop).toBe(2),
          three: (data) => expect(data.myprop).toBe(2)
        };

        const spyOne = spyOn(callbacks, 'one');
        const spyTwo = spyOn(callbacks, 'two');
        const spyThree = spyOn(callbacks, 'three');

        this.MockResource.subscribe(callbacks.one);
        this.MockResource.subscribe(callbacks.two);
        this.MockResource.subscribe(callbacks.three);

        state.myprop++;

        this.MockResource.publish(state);

        expect(spyOne).toHaveBeenCalled();
        expect(spyTwo).toHaveBeenCalled();
        expect(spyThree).toHaveBeenCalled();
      });
    });
  });
})(window.gl || (window.gl = {}));
