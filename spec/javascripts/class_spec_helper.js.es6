/* eslint-disable no-unused-vars */

class ClassSpecHelper {
  static itShouldBeAStaticMethod(base, method) {
    return it('should be a static method', () => {
      expect(base[method]).toBeDefined();
      expect(base.prototype[method]).toBeUndefined();
    });
  }
}
