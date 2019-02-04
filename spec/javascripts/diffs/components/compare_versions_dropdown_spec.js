// TODO: https://gitlab.com/gitlab-org/gitlab-ce/issues/48034
import { shallowMount, createLocalVue } from '@vue/test-utils';
import CompareVersionsDropdown from '~/diffs/components/compare_versions_dropdown.vue';
import diffsMockData from '../mock_data/merge_request_diffs';

describe('CompareVersionsDropdown', () => {
  let wrapper;
  const targetBranch = { branchName: 'tmp-wine-dev', versionIndex: -1 };

  const factory = (options = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(CompareVersionsDropdown, { localVue, ...options });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render a correct base version link', () => {
    factory({
      propsData: {
        baseVersionPath: '/gnuwget/wget2/merge_requests/6/diffs?diff_id=37',
        otherVersions: diffsMockData.slice(1),
        targetBranch,
      },
    });

    const links = wrapper.findAll('a');
    const lastLink = links.wrappers[links.length - 1];

    expect(lastLink.attributes('href')).toEqual(wrapper.props('baseVersionPath'));
  });
});
