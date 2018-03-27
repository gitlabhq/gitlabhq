// eslint-disable-next-line import/prefer-default-export
export const resetStore = (store) => {
  store.replaceState({
    notes: [],
    targetNoteHash: null,
    lastFetchedAt: null,

    notesData: {},
    userData: {},
    noteableData: {},
  });
};
