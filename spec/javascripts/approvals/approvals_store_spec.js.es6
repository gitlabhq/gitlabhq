require('es6-promise').polyfill();
require('~/merge_request_widget/approvals/approvals_store');

$.rails = {
  csrfToken() {},
};

(() => {
  // stand in for promise returned by api calls
  const mockThenable = {
    then() {
      return {
        catch() {},
      };
    },
    catch() {},
  };

  const mockRootStore = {
    data: {},
    rootEl: {
      dataset: {
        endpoint: 'gitlab/myendpoint/',
      },
    },
    assignToData(key, val) {
      return { key, val };
    },
  };

  describe('Approvals Store', function () {
    beforeEach(function () {
      this.rootStore = mockRootStore;
      this.approvalsStore = new gl.MergeRequestApprovalsStore(this.rootStore);
    });

    it('should define all needed approval api calls', function () {
      expect(this.approvalsStore.fetch).toBeDefined();
      expect(this.approvalsStore.approve).toBeDefined();
      expect(this.approvalsStore.unapprove).toBeDefined();
    });

    it('should only init the store once', function () {
      spyOn(this.approvalsStore, 'fetch').and.callFake(() => mockThenable);

      this.approvalsStore.initStoreOnce();
      this.approvalsStore.initStoreOnce();
      this.approvalsStore.initStoreOnce();

      expect(this.approvalsStore.fetch.calls.count()).toBe(1);
    });

    it('should be able to write to the rootStore', function () {
      const dataToStore = { myMockData: 'string' };

      spyOn(this.rootStore, 'assignToData');

      this.approvalsStore.assignToRootStore('approvals', dataToStore);

      expect(this.rootStore.assignToData).toHaveBeenCalled();
      expect(this.rootStore.assignToData).toHaveBeenCalledWith('approvals', dataToStore);
    });
  });
})(window.gl || (window.gl = {}));
