//= require lib/utils/custom_event_polyfill

describe('Custom Event Polyfill', () => {
  it('should be defined', () => {
    expect(window.CustomEvent).toBeDefined();
  });

  it('should create a `CustomEvent` instance', () => {
    const e = new window.CustomEvent('foo');

    expect(e.type).toEqual('foo');
    expect(e.bubbles).toBe(false);
    expect(e.cancelable).toBe(false);
    expect(e.detail).toBeFalsy();
  });

  it('should create a `CustomEvent` instance with a `details` object', () => {
    const e = new window.CustomEvent('bar', { detail: { foo: 'bar' } });

    expect(e.type).toEqual('bar');
    expect(e.bubbles).toBe(false);
    expect(e.cancelable).toBe(false);
    expect(e.detail.foo).toEqual('bar');
  });

  it('should create a `CustomEvent` instance with a `bubbles` boolean', () => {
    const e = new window.CustomEvent('bar', { bubbles: true });

    expect(e.type).toEqual('bar');
    expect(e.bubbles).toBe(true);
    expect(e.cancelable).toBe(false);
    expect(e.detail).toBeFalsy();
  });

  it('should create a `CustomEvent` instance with a `cancelable` boolean', () => {
    const e = new window.CustomEvent('bar', { cancelable: true });

    expect(e.type).toEqual('bar');
    expect(e.bubbles).toBe(false);
    expect(e.cancelable).toBe(true);
    expect(e.detail).toBeFalsy();
  });
});
