import BlobForkSuggestion from '~/blob/blob_fork_suggestion';

describe('BlobForkSuggestion', () => {
  let blobForkSuggestion;

<<<<<<< HEAD
  const openButtons = [document.createElement('div')];
  const forkButtons = [document.createElement('a')];
  const cancelButtons = [document.createElement('div')];
  const suggestionSections = [document.createElement('div')];
  const actionTextPieces = [document.createElement('div')];

  beforeEach(() => {
    blobForkSuggestion = new BlobForkSuggestion({
      openButtons,
      forkButtons,
      cancelButtons,
      suggestionSections,
      actionTextPieces,
    });
=======
  const openButton = document.createElement('div');
  const forkButton = document.createElement('a');
  const cancelButton = document.createElement('div');
  const suggestionSection = document.createElement('div');
  const actionTextPiece = document.createElement('div');

  beforeEach(() => {
    blobForkSuggestion = new BlobForkSuggestion({
      openButtons: openButton,
      forkButtons: forkButton,
      cancelButtons: cancelButton,
      suggestionSections: suggestionSection,
      actionTextPieces: actionTextPiece,
    })
      .init();
>>>>>>> 847790478f8d85607eacedcdb693cfcd25c415af
  });

  afterEach(() => {
    blobForkSuggestion.destroy();
  });

  it('showSuggestionSection', () => {
    blobForkSuggestion.showSuggestionSection('/foo', 'foo');
<<<<<<< HEAD
    expect(suggestionSections[0].classList.contains('hidden')).toEqual(false);
    expect(forkButtons[0].getAttribute('href')).toEqual('/foo');
    expect(actionTextPieces[0].textContent).toEqual('foo');
=======
    expect(suggestionSection.classList.contains('hidden')).toEqual(false);
    expect(forkButton.getAttribute('href')).toEqual('/foo');
    expect(actionTextPiece.textContent).toEqual('foo');
>>>>>>> 847790478f8d85607eacedcdb693cfcd25c415af
  });

  it('hideSuggestionSection', () => {
    blobForkSuggestion.hideSuggestionSection();
<<<<<<< HEAD
    expect(suggestionSections[0].classList.contains('hidden')).toEqual(true);
=======
    expect(suggestionSection.classList.contains('hidden')).toEqual(true);
>>>>>>> 847790478f8d85607eacedcdb693cfcd25c415af
  });
});
