import deepMerge from '~/lib/utils/deep_merge';

/**
 * This array of objects is used to test the following cases:
 * - [x] merging more than 2 objects
 * - [x] merging shallow properties
 * - [x] merging deep properties
 * - [x] overwriting when the source property is not mergeable
 * - [x] overwriting when the target property is not mergeable
 */
const getTestArgs = () => [
  {
    foo: {
      author: 'Franz',
      chapter: {
        page: 3,
      },
    },
    bar: null,
  },
  {
    foo: {
      author: 'Franz Kafka',
      title: 'The Trial',
    },
    bar: {
      zoo: 'ny',
      animal: 'monkey',
    },
  },
  {
    foo: {
      chapter: {
        page: 3,
        title: 'The First Chapter',
      },
    },
    bar: {
      zoo: 'la',
    },
    car: 'fast',
  },
];

const TEST_RESULT = {
  foo: {
    author: 'Franz Kafka',
    chapter: {
      page: 3,
      title: 'The First Chapter',
    },
    title: 'The Trial',
  },
  bar: {
    zoo: 'la',
    animal: 'monkey',
  },
  car: 'fast',
};

describe('deepMerge', () => {
  it('merges objects deeply', () => {
    const args = getTestArgs();

    const result = deepMerge(...args);

    expect(result).toEqual(TEST_RESULT);
  });

  it('does not mutate objects', () => {
    const args = getTestArgs();
    const origJSON = JSON.stringify(args);

    deepMerge(...args);

    expect(JSON.stringify(args)).toEqual(origJSON);
  });
});
