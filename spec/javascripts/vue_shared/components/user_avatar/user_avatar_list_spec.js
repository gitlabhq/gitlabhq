import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { TEST_HOST } from 'spec/test_constants';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

const TEST_IMAGE_SIZE = 7;
const TEST_BREAKPOINT = 5;

const createUser = id => ({
  id,
  name: 'Lorem',
  web_url: `${TEST_HOST}/${id}`,
  avatar_url: `${TEST_HOST}/${id}/avatar`,
});
const createList = n =>
  Array(n)
    .fill(1)
    .map((x, id) => createUser(id));

const localVue = createLocalVue();

describe('UserAvatarList', () => {
  let propsData;
  let wrapper;

  const factory = options => {
    wrapper = shallowMount(localVue.extend(UserAvatarList), {
      localVue,
      propsData,
      ...options,
    });
  };

  const clickButton = () => {
    const button = wrapper.find(GlButton);
    button.vm.$emit('click');
  };

  beforeEach(() => {
    propsData = { imgSize: TEST_IMAGE_SIZE };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with no breakpoint', () => {
    beforeEach(() => {
      propsData.breakpoint = 0;
    });

    it('renders avatars', () => {
      const items = createList(20);
      propsData.items = items;
      factory();

      const links = wrapper.findAll(UserAvatarLink);
      const linkProps = links.wrappers.map(x => x.props());

      expect(linkProps).toEqual(
        propsData.items.map(x =>
          jasmine.objectContaining({
            linkHref: x.web_url,
            imgSrc: x.avatar_url,
            imgAlt: x.name,
            tooltipText: x.name,
            imgSize: TEST_IMAGE_SIZE,
          }),
        ),
      );
    });
  });

  describe('with breakpoint and length equal to breakpoint', () => {
    beforeEach(() => {
      propsData.breakpoint = TEST_BREAKPOINT;
      propsData.items = createList(TEST_BREAKPOINT);
    });

    it('renders all avatars if length is <= breakpoint', () => {
      factory();

      const links = wrapper.findAll(UserAvatarLink);

      expect(links.length).toEqual(propsData.items.length);
    });

    it('does not show button', () => {
      factory();

      expect(wrapper.find(GlButton).exists()).toBe(false);
    });
  });

  describe('with breakpoint and length greater than breakpoint', () => {
    beforeEach(() => {
      propsData.breakpoint = TEST_BREAKPOINT;
      propsData.items = createList(TEST_BREAKPOINT + 1);
    });

    it('renders avatars up to breakpoint', () => {
      factory();

      const links = wrapper.findAll(UserAvatarLink);

      expect(links.length).toEqual(TEST_BREAKPOINT);
    });

    describe('with expand clicked', () => {
      beforeEach(() => {
        factory();
        clickButton();
      });

      it('renders all avatars', () => {
        const links = wrapper.findAll(UserAvatarLink);

        expect(links.length).toEqual(propsData.items.length);
      });

      it('with collapse clicked, it renders avatars up to breakpoint', () => {
        clickButton();
        const links = wrapper.findAll(UserAvatarLink);

        expect(links.length).toEqual(TEST_BREAKPOINT);
      });
    });
  });
});
