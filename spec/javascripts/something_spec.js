import * as something from './something';

fdescribe('something', () => {
  it('does not call someFunction', () => {
    spyOn(something, 'someFunction').and.callFake(() => console.log('someFunction was not called! yay!'));
    something.otherFunction();
  });
});
