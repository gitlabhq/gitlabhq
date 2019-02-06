import ServerlessStore from '~/serverless/stores/serverless_store';
import { mockServerlessFunctions, mockServerlessFunctionsDiffEnv } from '../mock_data';

describe('Serverless Functions Store', () => {
  let store;

  beforeEach(() => {
    store = new ServerlessStore(false, '/cluster_path', 'help_path');
  });

  describe('#updateFunctionsFromServer', () => {
    it('should pass an empty hash object', () => {
      store.updateFunctionsFromServer();

      expect(store.state.functions).toEqual({});
    });

    it('should group functions to one global environment', () => {
      const mockServerlessData = mockServerlessFunctions;
      store.updateFunctionsFromServer(mockServerlessData);

      expect(Object.keys(store.state.functions)).toEqual(jasmine.objectContaining(['*']));
      expect(store.state.functions['*'].length).toEqual(2);
    });

    it('should group functions to multiple environments', () => {
      const mockServerlessData = mockServerlessFunctionsDiffEnv;
      store.updateFunctionsFromServer(mockServerlessData);

      expect(Object.keys(store.state.functions)).toEqual(jasmine.objectContaining(['*']));
      expect(store.state.functions['*'].length).toEqual(1);
      expect(store.state.functions.test.length).toEqual(1);
      expect(store.state.functions.test[0].name).toEqual('testfunc2');
    });
  });
});
