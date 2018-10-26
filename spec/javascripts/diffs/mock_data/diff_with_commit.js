import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const FIXTURE = 'merge_request_diffs/with_commit.json';

preloadFixtures(FIXTURE);

export default function getDiffWithCommit() {
  return convertObjectPropsToCamelCase(getJSONFixture(FIXTURE), { deep: true });
}
