import BlobForkSuggestion from '~/blob/blob_fork_suggestion';

describe('BlobForkSuggestion', () => {
  let blobForkSuggestion;

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
  });

  afterEach(() => {
    blobForkSuggestion.destroy();
  });

  it('showSuggestionSection', () => {
    blobForkSuggestion.showSuggestionSection('/foo', 'foo');
    expect(suggestionSections[0].classList.contains('hidden')).toEqual(false);
    expect(forkButtons[0].getAttribute('href')).toEqual('/foo');
    expect(actionTextPieces[0].textContent).toEqual('foo');
  });

  it('hideSuggestionSection', () => {
    blobForkSuggestion.hideSuggestionSection();
    expect(suggestionSections[0].classList.contains('hidden')).toEqual(true);
  });
});
