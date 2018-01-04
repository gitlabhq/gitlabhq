import editorOptions from '~/ide/lib/editor_options';

describe('Multi-file editor library editor options', () => {
  it('returns an array', () => {
    expect(editorOptions).toEqual(jasmine.any(Array));
  });
});
