/* global ClassSpecHelper */

import './class_spec_helper';

describe('ClassSpecHelper', function () {
  describe('itShouldBeAStaticMethod', () => {
    beforeEach(() => {
      class TestClass {
        instanceMethod() { this.prop = 'val'; }
        static staticMethod() {}
      }

      this.TestClass = TestClass;
    });

    ClassSpecHelper.itShouldBeAStaticMethod(ClassSpecHelper, 'itShouldBeAStaticMethod');
  });
});
