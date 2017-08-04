describe('issue_comment_form component', () => {

  describe('user is logged in', () => {
    it('should render user avatar with link', () => {

    });

    describe('textarea', () => {
      it('should render textarea with placeholder', () => {

      });

      it('should support quick actions', () => {

      });

      it('should link to markdown docs', () => {

      });

      it('should link to quick actions docs', () => {

      });

      describe('edit mode', () => {
        it('should enter edit mode when arrow up is pressed', () => {

        });
      });

      describe('preview mode', () => {
        it('should be possible to preview the note', () => {

        });
      });

      describe('event enter', () => {
        it('should save note when cmd/ctrl+enter is pressed', () => {

        });
      });
    });

    describe('actions', () => {
      describe('with empty note', () => {
        it('should render dropdown as disabled', () => {

        });
      });

      describe('with note', () => {
        it('should render enabled dropdown with 2 actions', () => {

        });

        it('should render be possible to discard draft', () => {

        });
      });

      describe('with open issue', () => {
        it('should be possible to close the issue', () => {

        });
      });

      describe('with closed issue', () => {
        it('should be possible to reopen the issue', () => {

        });
      });
    });


  });

  describe('user is not logged in', () => {
    it('should render signed out widget', () => {

    });

    it('should not render submission form', () => {

    });
  });
});