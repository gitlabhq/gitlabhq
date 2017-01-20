/* eslint-disable no-unused-vars */

class ClassSpecHelper {
  static itShouldBeAStaticMethod(base, method) {
    return it('should be a static method', () => {
      expect(Object.prototype.hasOwnProperty.call(base, method)).toBeTruthy();
    });
  }
}
