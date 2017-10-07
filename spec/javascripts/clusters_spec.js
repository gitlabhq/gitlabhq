import Clusters from '~/clusters';

describe('Clusters', () => {
  let cluster;
  preloadFixtures('clusters/show_cluster.html.raw');

  beforeEach(() => {
    loadFixtures('clusters/show_cluster.html.raw');
    cluster = new Clusters();
  });

  describe('toggle', () => {
    it('should update the button and the input field on click', () => {
      cluster.toggleButton.click();

      expect(
        cluster.toggleButton.classList,
      ).not.toContain('checked');

      expect(
        cluster.toggleInput.getAttribute('value'),
      ).toEqual('false');
    });
  });

  describe('updateContainer', () => {
    describe('when creating cluster', () => {
      it('should show the creating container', () => {
        cluster.updateContainer('creating');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeFalsy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeTruthy();
      });
    });

    describe('when cluster is created', () => {
      it('should show the success container', () => {
        cluster.updateContainer('created');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeFalsy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeTruthy();
      });
    });

    describe('when cluster has error', () => {
      it('should show the error container', () => {
        cluster.updateContainer('errored', 'this is an error');

        expect(
          cluster.creatingContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.successContainer.classList.contains('hidden'),
        ).toBeTruthy();
        expect(
          cluster.errorContainer.classList.contains('hidden'),
        ).toBeFalsy();

        expect(
          cluster.errorReasonContainer.textContent,
        ).toContain('this is an error');
      });
    });
  });
});
