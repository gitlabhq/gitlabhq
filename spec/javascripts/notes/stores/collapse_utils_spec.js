import {
  isSystemNote,
  changeDescriptionNote,
  getTimeDifferenceMinutes,
} from '~/notes/stores/collapse_utils';

describe('Collapse utils', () => {
  const mockSystemNote = {
    note: 'changed the description',
    note_html: '<p dir="auto">changed the description</p>',
    system: true,
    created_at: '2018-05-14T21:28:00.000Z',
  };

  it('checks if a system note is of a description type', () => {
    expect(isSystemNote(mockSystemNote)).toEqual(true);
  });

  it('changes the description to contain the number of changed times', () => {
    const changedNote = changeDescriptionNote(mockSystemNote, 3, 5);

    expect(changedNote.times_updated).toEqual(3);
    expect(changedNote.note_html.trim()).toContain('<p dir="auto">changed the description 3 times within 5 minutes, </p>');
  });

  it('gets the time difference between two notes', () => {
    const anotherSystemNote = {
      created_at: '2018-05-14T21:33:00.000Z',
    };

    expect(getTimeDifferenceMinutes(mockSystemNote, anotherSystemNote)).toEqual(5);
  });
});
