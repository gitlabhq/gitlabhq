import { GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import ResolveWithIssueButton from '~/notes/components/discussion_resolve_with_issue_button.vue';

const localVue = createLocalVue();

describe('ResolveWithIssueButton', () => {
  let wrapper;
  const url = `${TEST_HOST}/hello-world/`;

  beforeEach(() => {
    wrapper = shallowMount(ResolveWithIssueButton, {
      localVue,
      sync: false,
      propsData: {
        url,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('it should have a link with the provided link property as href', () => {
    const button = wrapper.find(GlButton);

    expect(button.attributes().href).toBe(url);
  });
});
