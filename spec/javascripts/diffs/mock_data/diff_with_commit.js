const FIXTURE = 'merge_request_diffs/with_commit.json';

preloadFixtures(FIXTURE);

export default function getDiffWithCommit() {
  return getJSONFixture(FIXTURE);
}
