require('~/extensions/object');

describe('Object extensions', () => {
  describe('assign', () => {
    it('merges source object into target object', () => {
      const targetObj = {};
      const sourceObj = {
        foo: 'bar',
      };
      Object.assign(targetObj, sourceObj);
      expect(targetObj.foo).toBe('bar');
    });

    it('merges object with the same properties', () => {
      const targetObj = {
        foo: 'bar',
      };
      const sourceObj = {
        foo: 'baz',
      };
      Object.assign(targetObj, sourceObj);
      expect(targetObj.foo).toBe('baz');
    });
  });
});
