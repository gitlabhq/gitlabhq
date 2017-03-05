/* global ClassSpecHelper */

require('./class_spec_helper');

describe('ClassSpecHelper', () => {
  describe('.itShouldBeAStaticMethod', function () {
    beforeEach(() => {
      class TestClass {
        instanceMethod() { this.prop = 'val'; }
        static staticMethod() {}
      }

      this.TestClass = TestClass;
    });

    ClassSpecHelper.itShouldBeAStaticMethod(ClassSpecHelper, 'itShouldBeAStaticMethod');

    it('should have a defined spec', () => {
      expect(ClassSpecHelper.itShouldBeAStaticMethod(this.TestClass, 'staticMethod').description).toBe('should be a static method');
    });

    it('should pass for a static method', () => {
      const spec = ClassSpecHelper.itShouldBeAStaticMethod(this.TestClass, 'staticMethod');
      expect(spec.status()).toBe('passed');
    });

    it('should fail for an instance method', (done) => {
      const spec = ClassSpecHelper.itShouldBeAStaticMethod(this.TestClass, 'instanceMethod');
      spec.resultCallback = (result) => {
        expect(result.status).toBe('failed');
        done();
      };
      spec.execute();
    });
  });
});
