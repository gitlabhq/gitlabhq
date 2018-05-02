import $ from 'jquery';
import DeleteModal from '~/branches/branches_delete_modal';

describe('branches delete modal', () => {
  describe('setDisableDeleteButton', () => {
    let submitSpy;
    let $deleteButton;

    beforeEach(() => {
      setFixtures(`
        <div id="modal-delete-branch">
          <form>
            <button type="submit" class="js-delete-branch">Delete</button>
          </form>
        </div>
      `);
      $deleteButton = $('.js-delete-branch');
      submitSpy = jasmine.createSpy('submit').and.callFake(event => event.preventDefault());
      $('#modal-delete-branch form').on('submit', submitSpy);
      // eslint-disable-next-line no-new
      new DeleteModal();
    });

    it('does not submit if button is disabled', () => {
      $deleteButton.attr('disabled', true);

      $deleteButton.click();

      expect(submitSpy).not.toHaveBeenCalled();
    });

    it('submits if button is not disabled', () => {
      $deleteButton.attr('disabled', false);

      $deleteButton.click();

      expect(submitSpy).toHaveBeenCalled();
    });
  });
});
