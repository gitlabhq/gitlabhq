import BlobForkSuggestion from '~/blob/blob_fork_suggestion';

describe('BlobForkSuggestion', () => {
  let blobForkSuggestion;

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
    }).init();
  });

  afterEach(() => {
    blobForkSuggestion.destroy();
  });

  it('showSuggestionSection', () => {
    blobForkSuggestion.showSuggestionSection('/foo', 'foo');

    expect(suggestionSection.classList.contains('hidden')).toEqual(false);
    expect(forkButton.getAttribute('href')).toEqual('/foo');
    expect(actionTextPiece.textContent).toEqual('foo');
  });

  it('hideSuggestionSection', () => {
    blobForkSuggestion.hideSuggestionSection();

    expect(suggestionSection.classList.contains('hidden')).toEqual(true);
  });
});
