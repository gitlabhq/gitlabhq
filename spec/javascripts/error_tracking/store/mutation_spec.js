import mutations from '~/error_tracking/store/mutations';
import * as types from '~/error_tracking/store/mutation_types';

describe('Error tracking mutations', () => {
  describe('SET_ERRORS', () => {
    let state;

    beforeEach(() => {
      state = { errors: [] };
    });

    it('camelizes response', () => {
      const errors = [
        {
          title: 'the title',
          external_url: 'localhost:3456',
          count: 100,
          userCount: 10,
        },
      ];

      mutations[types.SET_ERRORS](state, errors);

      expect(state).toEqual({
        errors: [
          {
            title: 'the title',
            externalUrl: 'localhost:3456',
            count: 100,
            userCount: 10,
          },
        ],
      });
    });
  });
});
