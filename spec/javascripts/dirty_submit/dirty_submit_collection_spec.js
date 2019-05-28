import DirtySubmitCollection from '~/dirty_submit/dirty_submit_collection';
import { setInputValue, createForm } from './helper';

describe('DirtySubmitCollection', () => {
  it('disables submits until there are changes', done => {
    const testElementsCollection = [createForm(), createForm()];
    const forms = testElementsCollection.map(testElements => testElements.form);

    new DirtySubmitCollection(forms); // eslint-disable-line no-new

    testElementsCollection.forEach(testElements => {
      const { input, submit } = testElements;
      const originalValue = input.value;

      expect(submit.disabled).toBe(true);

      return setInputValue(input, `${originalValue} changes`)
        .then(() => {
          expect(submit.disabled).toBe(false);
        })
        .then(() => setInputValue(input, originalValue))
        .then(() => {
          expect(submit.disabled).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
