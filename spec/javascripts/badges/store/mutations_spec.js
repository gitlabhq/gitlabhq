import { GROUP_BADGE, PROJECT_BADGE } from '~/badges/constants';
import store from '~/badges/store';
import types from '~/badges/store/mutation_types';
import createState from '~/badges/store/state';
import { createDummyBadge } from '../dummy_badge';

describe('Badges store mutations', () => {
  let dummyBadge;

  beforeEach(() => {
    dummyBadge = createDummyBadge();
    store.replaceState(createState());
  });

  describe('RECEIVE_DELETE_BADGE', () => {
    beforeEach(() => {
      const badges = [
        { ...dummyBadge, id: dummyBadge.id - 1 },
        dummyBadge,
        { ...dummyBadge, id: dummyBadge.id + 1 },
      ];

      store.replaceState({
        ...store.state,
        badges,
      });
    });

    it('removes deleted badge', () => {
      const badgeCount = store.state.badges.length;

      store.commit(types.RECEIVE_DELETE_BADGE, dummyBadge.id);

      expect(store.state.badges.length).toBe(badgeCount - 1);
      expect(store.state.badges.indexOf(dummyBadge)).toBe(-1);
    });
  });

  describe('RECEIVE_DELETE_BADGE_ERROR', () => {
    beforeEach(() => {
      const badges = [
        { ...dummyBadge, id: dummyBadge.id - 1, isDeleting: false },
        { ...dummyBadge, isDeleting: true },
        { ...dummyBadge, id: dummyBadge.id + 1, isDeleting: true },
      ];

      store.replaceState({
        ...store.state,
        badges,
      });
    });

    it('sets isDeleting to false', () => {
      const badgeCount = store.state.badges.length;

      store.commit(types.RECEIVE_DELETE_BADGE_ERROR, dummyBadge.id);

      expect(store.state.badges.length).toBe(badgeCount);
      expect(store.state.badges[0].isDeleting).toBe(false);
      expect(store.state.badges[1].isDeleting).toBe(false);
      expect(store.state.badges[2].isDeleting).toBe(true);
    });
  });

  describe('RECEIVE_LOAD_BADGES', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isLoading: 'not false',
      });
    });

    it('sets badges and isLoading to false', () => {
      const badges = [createDummyBadge()];
      store.commit(types.RECEIVE_LOAD_BADGES, badges);

      expect(store.state.isLoading).toBe(false);
      expect(store.state.badges).toBe(badges);
    });
  });

  describe('RECEIVE_LOAD_BADGES_ERROR', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isLoading: 'not false',
      });
    });

    it('sets isLoading to false', () => {
      store.commit(types.RECEIVE_LOAD_BADGES_ERROR);

      expect(store.state.isLoading).toBe(false);
    });
  });

  describe('RECEIVE_NEW_BADGE', () => {
    beforeEach(() => {
      const badges = [
        { ...dummyBadge, id: dummyBadge.id - 1, kind: GROUP_BADGE },
        { ...dummyBadge, id: dummyBadge.id + 1, kind: GROUP_BADGE },
        { ...dummyBadge, id: dummyBadge.id - 1, kind: PROJECT_BADGE },
        { ...dummyBadge, id: dummyBadge.id + 1, kind: PROJECT_BADGE },
      ];
      store.replaceState({
        ...store.state,
        badgeInAddForm: createDummyBadge(),
        badges,
        isSaving: 'dummy value',
        renderedBadge: createDummyBadge(),
      });
    });

    it('resets the add form', () => {
      store.commit(types.RECEIVE_NEW_BADGE, dummyBadge);

      expect(store.state.badgeInAddForm).toBe(null);
      expect(store.state.isSaving).toBe(false);
      expect(store.state.renderedBadge).toBe(null);
    });

    it('inserts group badge at correct position', () => {
      const badgeCount = store.state.badges.length;
      dummyBadge = { ...dummyBadge, kind: GROUP_BADGE };

      store.commit(types.RECEIVE_NEW_BADGE, dummyBadge);

      expect(store.state.badges.length).toBe(badgeCount + 1);
      expect(store.state.badges.indexOf(dummyBadge)).toBe(1);
    });

    it('inserts project badge at correct position', () => {
      const badgeCount = store.state.badges.length;
      dummyBadge = { ...dummyBadge, kind: PROJECT_BADGE };

      store.commit(types.RECEIVE_NEW_BADGE, dummyBadge);

      expect(store.state.badges.length).toBe(badgeCount + 1);
      expect(store.state.badges.indexOf(dummyBadge)).toBe(3);
    });
  });

  describe('RECEIVE_NEW_BADGE_ERROR', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isSaving: 'dummy value',
      });
    });

    it('sets isSaving to false', () => {
      store.commit(types.RECEIVE_NEW_BADGE_ERROR);

      expect(store.state.isSaving).toBe(false);
    });
  });

  describe('RECEIVE_RENDERED_BADGE', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isRendering: 'dummy value',
        renderedBadge: 'dummy value',
      });
    });

    it('sets renderedBadge', () => {
      store.commit(types.RECEIVE_RENDERED_BADGE, dummyBadge);

      expect(store.state.isRendering).toBe(false);
      expect(store.state.renderedBadge).toBe(dummyBadge);
    });
  });

  describe('RECEIVE_RENDERED_BADGE_ERROR', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isRendering: 'dummy value',
      });
    });

    it('sets isRendering to false', () => {
      store.commit(types.RECEIVE_RENDERED_BADGE_ERROR);

      expect(store.state.isRendering).toBe(false);
    });
  });

  describe('RECEIVE_UPDATED_BADGE', () => {
    beforeEach(() => {
      const badges = [
        { ...dummyBadge, id: dummyBadge.id - 1 },
        dummyBadge,
        { ...dummyBadge, id: dummyBadge.id + 1 },
      ];
      store.replaceState({
        ...store.state,
        badgeInEditForm: createDummyBadge(),
        badges,
        isEditing: 'dummy value',
        isSaving: 'dummy value',
        renderedBadge: createDummyBadge(),
      });
    });

    it('resets the edit form', () => {
      store.commit(types.RECEIVE_UPDATED_BADGE, dummyBadge);

      expect(store.state.badgeInAddForm).toBe(null);
      expect(store.state.isSaving).toBe(false);
      expect(store.state.renderedBadge).toBe(null);
    });

    it('replaces the updated badge', () => {
      const badgeCount = store.state.badges.length;
      const badgeIndex = store.state.badges.indexOf(dummyBadge);
      const newBadge = { id: dummyBadge.id, dummy: 'value' };

      store.commit(types.RECEIVE_UPDATED_BADGE, newBadge);

      expect(store.state.badges.length).toBe(badgeCount);
      expect(store.state.badges[badgeIndex]).toBe(newBadge);
    });
  });

  describe('RECEIVE_UPDATED_BADGE_ERROR', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isSaving: 'dummy value',
      });
    });

    it('sets isSaving to false', () => {
      store.commit(types.RECEIVE_NEW_BADGE_ERROR);

      expect(store.state.isSaving).toBe(false);
    });
  });

  describe('REQUEST_DELETE_BADGE', () => {
    beforeEach(() => {
      const badges = [
        { ...dummyBadge, id: dummyBadge.id - 1, isDeleting: false },
        { ...dummyBadge, isDeleting: false },
        { ...dummyBadge, id: dummyBadge.id + 1, isDeleting: true },
      ];

      store.replaceState({
        ...store.state,
        badges,
      });
    });

    it('sets isDeleting to true', () => {
      const badgeCount = store.state.badges.length;

      store.commit(types.REQUEST_DELETE_BADGE, dummyBadge.id);

      expect(store.state.badges.length).toBe(badgeCount);
      expect(store.state.badges[0].isDeleting).toBe(false);
      expect(store.state.badges[1].isDeleting).toBe(true);
      expect(store.state.badges[2].isDeleting).toBe(true);
    });
  });

  describe('REQUEST_LOAD_BADGES', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        apiEndpointUrl: 'some endpoint',
        docsUrl: 'some url',
        isLoading: 'dummy value',
        kind: 'some kind',
      });
    });

    it('sets isLoading to true and initializes the store', () => {
      const dummyData = {
        apiEndpointUrl: 'dummy endpoint',
        docsUrl: 'dummy url',
        kind: 'dummy kind',
      };

      store.commit(types.REQUEST_LOAD_BADGES, dummyData);

      expect(store.state.isLoading).toBe(true);
      expect(store.state.apiEndpointUrl).toBe(dummyData.apiEndpointUrl);
      expect(store.state.docsUrl).toBe(dummyData.docsUrl);
      expect(store.state.kind).toBe(dummyData.kind);
    });
  });

  describe('REQUEST_NEW_BADGE', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isSaving: 'dummy value',
      });
    });

    it('sets isSaving to true', () => {
      store.commit(types.REQUEST_NEW_BADGE);

      expect(store.state.isSaving).toBe(true);
    });
  });

  describe('REQUEST_RENDERED_BADGE', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isRendering: 'dummy value',
      });
    });

    it('sets isRendering to true', () => {
      store.commit(types.REQUEST_RENDERED_BADGE);

      expect(store.state.isRendering).toBe(true);
    });
  });

  describe('REQUEST_UPDATED_BADGE', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        isSaving: 'dummy value',
      });
    });

    it('sets isSaving to true', () => {
      store.commit(types.REQUEST_NEW_BADGE);

      expect(store.state.isSaving).toBe(true);
    });
  });

  describe('START_EDITING', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        badgeInEditForm: 'dummy value',
        isEditing: 'dummy value',
        renderedBadge: 'dummy value',
      });
    });

    it('initializes the edit form', () => {
      store.commit(types.START_EDITING, dummyBadge);

      expect(store.state.isEditing).toBe(true);
      expect(store.state.badgeInEditForm).toEqual(dummyBadge);
      expect(store.state.renderedBadge).toEqual(dummyBadge);
    });
  });

  describe('STOP_EDITING', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        badgeInEditForm: 'dummy value',
        isEditing: 'dummy value',
        renderedBadge: 'dummy value',
      });
    });

    it('resets the edit form', () => {
      store.commit(types.STOP_EDITING);

      expect(store.state.isEditing).toBe(false);
      expect(store.state.badgeInEditForm).toBe(null);
      expect(store.state.renderedBadge).toBe(null);
    });
  });

  describe('UPDATE_BADGE_IN_FORM', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        badgeInAddForm: 'dummy value',
        badgeInEditForm: 'dummy value',
      });
    });

    it('sets badgeInEditForm if isEditing is true', () => {
      store.state.isEditing = true;

      store.commit(types.UPDATE_BADGE_IN_FORM, dummyBadge);

      expect(store.state.badgeInEditForm).toBe(dummyBadge);
    });

    it('sets badgeInAddForm if isEditing is false', () => {
      store.state.isEditing = false;

      store.commit(types.UPDATE_BADGE_IN_FORM, dummyBadge);

      expect(store.state.badgeInAddForm).toBe(dummyBadge);
    });
  });

  describe('UPDATE_BADGE_IN_MODAL', () => {
    beforeEach(() => {
      store.replaceState({
        ...store.state,
        badgeInModal: 'dummy value',
      });
    });

    it('sets badgeInModal', () => {
      store.commit(types.UPDATE_BADGE_IN_MODAL, dummyBadge);

      expect(store.state.badgeInModal).toBe(dummyBadge);
    });
  });
});
