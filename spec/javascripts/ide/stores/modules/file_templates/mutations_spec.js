import createState from '~/ide/stores/modules/file_templates/state';
import * as types from '~/ide/stores/modules/file_templates/mutation_types';
import mutations from '~/ide/stores/modules/file_templates/mutations';

describe('IDE file templates mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.REQUEST_TEMPLATE_TYPES, () => {
    it('sets isLoading', () => {
      mutations[types.REQUEST_TEMPLATE_TYPES](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe(types.RECEIVE_TEMPLATE_TYPES_ERROR, () => {
    it('sets isLoading', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_TEMPLATE_TYPES_ERROR](state);

      expect(state.isLoading).toBe(false);
    });
  });

  describe(types.RECEIVE_TEMPLATE_TYPES_SUCCESS, () => {
    it('sets isLoading to false', () => {
      state.isLoading = true;

      mutations[types.RECEIVE_TEMPLATE_TYPES_SUCCESS](state, []);

      expect(state.isLoading).toBe(false);
    });

    it('sets templates', () => {
      mutations[types.RECEIVE_TEMPLATE_TYPES_SUCCESS](state, ['test']);

      expect(state.templates).toEqual(['test']);
    });
  });

  describe(types.SET_SELECTED_TEMPLATE_TYPE, () => {
    it('sets selectedTemplateType', () => {
      mutations[types.SET_SELECTED_TEMPLATE_TYPE](state, 'type');

      expect(state.selectedTemplateType).toBe('type');
    });
  });

  describe(types.SET_UPDATE_SUCCESS, () => {
    it('sets updateSuccess', () => {
      mutations[types.SET_UPDATE_SUCCESS](state, true);

      expect(state.updateSuccess).toBe(true);
    });
  });
});
