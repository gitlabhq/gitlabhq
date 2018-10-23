import Vue from 'vue';
import { TEST_HOST } from 'spec/test_constants';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/vue_component_helper';
import { getTimeago } from '~/lib/utils/datetime_utility';
import CommitItem from '~/diffs/components/commit_item.vue';
import getDiffWithCommit from '../mock_data/diff_with_commit';

const TEST_AUTHOR_NAME = 'test';
const TEST_AUTHOR_EMAIL = 'test+test@gitlab.com';
const TEST_AUTHOR_GRAVATAR = `${TEST_HOST}/avatar/test?s=36`;
const TEST_SIGNATURE_HTML = '<a>Legit commit</a>';
const TEST_PIPELINE_STATUS_PATH = `${TEST_HOST}/pipeline/status`;

const getTitleElement = vm => vm.$el.querySelector('.commit-row-message.item-title');
const getDescElement = vm => vm.$el.querySelector('pre.commit-row-description');
const getDescExpandElement = vm =>
  vm.$el.querySelector('.commit-content .text-expander.js-toggle-button');
const getShaElement = vm => vm.$el.querySelector('.commit-sha-group');
const getAvatarElement = vm => vm.$el.querySelector('.user-avatar-link');
const getCommitterElement = vm => vm.$el.querySelector('.commiter');
const getCommitActionsElement = vm => vm.$el.querySelector('.commit-actions');

describe('diffs/components/commit_widget', () => {
  const Component = Vue.extend(CommitItem);
  const timeago = getTimeago();
  const { commit } = getDiffWithCommit();

  let vm;

  beforeEach(() => {
    vm = mountComponent(Component, {
      commit: getDiffWithCommit().commit,
    });
  });

  it('renders commit title', () => {
    const titleElement = getTitleElement(vm);

    expect(titleElement).toHaveAttr('href', commit.commitUrl);
    expect(titleElement).toHaveText(commit.titleHtml);
  });

  it('renders commit description', () => {
    const descElement = getDescElement(vm);
    const descExpandElement = getDescExpandElement(vm);

    const expected = commit.descriptionHtml.replace(/&#x000A;/g, '');

    expect(trimText(descElement.innerHTML)).toEqual(trimText(expected));
    expect(descExpandElement).not.toBeNull();
  });

  it('renders commit sha', () => {
    const shaElement = getShaElement(vm);
    const labelElement = shaElement.querySelector('.label');
    const buttonElement = shaElement.querySelector('button');

    expect(labelElement.textContent).toEqual(commit.shortId);
    expect(buttonElement).toHaveData('clipboard-text', commit.id);
  });

  it('renders author avatar', () => {
    const avatarElement = getAvatarElement(vm);
    const imgElement = avatarElement.querySelector('img');

    expect(avatarElement).toHaveAttr('href', commit.author.webUrl);
    expect(imgElement).toHaveClass('s36');
    expect(imgElement).toHaveAttr('alt', commit.author.name);
    expect(imgElement).toHaveAttr('src', commit.author.avatarUrl);
  });

  it('renders committer text', () => {
    const committerElement = getCommitterElement(vm);
    const nameElement = committerElement.querySelector('a');

    const expectTimeText = timeago.format(commit.authoredDate);
    const expectedText = `${commit.author.name} authored ${expectTimeText}`;

    expect(trimText(committerElement.textContent)).toEqual(expectedText);
    expect(nameElement).toHaveAttr('href', commit.author.webUrl);
    expect(nameElement).toHaveText(commit.author.name);
  });

  describe('without commit description', () => {
    beforeEach(done => {
      vm.commit.descriptionHtml = '';

      vm.$nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('hides description', () => {
      const descElement = getDescElement(vm);
      const descExpandElement = getDescExpandElement(vm);

      expect(descElement).toBeNull();
      expect(descExpandElement).toBeNull();
    });
  });

  describe('with no matching user', () => {
    beforeEach(done => {
      vm.commit.author = null;
      vm.commit.authorEmail = TEST_AUTHOR_EMAIL;
      vm.commit.authorName = TEST_AUTHOR_NAME;
      vm.commit.authorGravatarUrl = TEST_AUTHOR_GRAVATAR;

      vm.$nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('renders author avatar', () => {
      const avatarElement = getAvatarElement(vm);
      const imgElement = avatarElement.querySelector('img');

      expect(avatarElement).toHaveAttr('href', `mailto:${TEST_AUTHOR_EMAIL}`);
      expect(imgElement).toHaveAttr('alt', TEST_AUTHOR_NAME);
      expect(imgElement).toHaveAttr('src', TEST_AUTHOR_GRAVATAR);
    });

    it('renders committer text', () => {
      const committerElement = getCommitterElement(vm);
      const nameElement = committerElement.querySelector('a');

      expect(nameElement).toHaveAttr('href', `mailto:${TEST_AUTHOR_EMAIL}`);
      expect(nameElement).toHaveText(TEST_AUTHOR_NAME);
    });
  });

  describe('with signature', () => {
    beforeEach(done => {
      vm.commit.signatureHtml = TEST_SIGNATURE_HTML;

      vm.$nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('renders signature html', () => {
      const actionsElement = getCommitActionsElement(vm);

      expect(actionsElement).toContainHtml(TEST_SIGNATURE_HTML);
    });
  });

  describe('with pipeline status', () => {
    beforeEach(done => {
      vm.commit.pipelineStatusPath = TEST_PIPELINE_STATUS_PATH;

      vm.$nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('renders pipeline status', () => {
      const actionsElement = getCommitActionsElement(vm);

      expect(actionsElement).toContainElement('.ci-status-link');
    });
  });
});
