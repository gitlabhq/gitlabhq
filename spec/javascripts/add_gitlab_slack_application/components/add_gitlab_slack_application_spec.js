import Vue from 'vue';
import addGitlabSlackApplication from 'ee/add_gitlab_slack_application/components/add_gitlab_slack_application.vue';
import GitlabSlackService from 'ee/add_gitlab_slack_application/services/gitlab_slack_service';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('AddGitlabSlackApplication', () => {
  const redirectLink = '//redirectLink';
  const gitlabForSlackGifPath = '//gitlabForSlackGifPath';
  const signInPath = '//signInPath';
  const slackLinkPath = '//slackLinkPath';
  const docsPath = '//docsPath';
  const gitlabLogoPath = '//gitlabLogoPath';
  const slackLogoPath = '//slackLogoPath';
  const projects = [{
    id: 4,
    name: 'test',
  }, {
    id: 6,
    name: 'nope',
  }];
  const DEFAULT_PROPS = {
    projects,
    gitlabForSlackGifPath,
    signInPath,
    slackLinkPath,
    docsPath,
    gitlabLogoPath,
    slackLogoPath,
    isSignedIn: false,
  };

  const AddGitlabSlackApplication = Vue.extend(addGitlabSlackApplication);

  it('opens popup when button is clicked', (done) => {
    const vm = mountComponent(AddGitlabSlackApplication, DEFAULT_PROPS);

    vm.$el.querySelector('.js-popup-button').click();

    vm.$nextTick()
      .then(() => expect(vm.$el.querySelector('.js-popup')).toBeDefined())
      .then(done)
      .catch(done.fail);
  });

  it('hides popup when button is clicked', (done) => {
    const vm = mountComponent(AddGitlabSlackApplication, DEFAULT_PROPS);

    vm.popupOpen = true;

    vm.$nextTick()
      .then(() => vm.$el.querySelector('.js-popup-button').click())
      .then(vm.$nextTick)
      .then(() => expect(vm.$el.querySelector('.js-popup')).toBeNull())
      .then(done)
      .catch(done.fail);
  });

  it('popup has a project select when signed in', (done) => {
    const vm = mountComponent(AddGitlabSlackApplication, {
      ...DEFAULT_PROPS,
      isSignedIn: true,
    });

    vm.popupOpen = true;

    vm.$nextTick()
      .then(() => expect(vm.$el.querySelector('.js-project-select')).toBeDefined())
      .then(done)
      .catch(done.fail);
  });

  it('popup has a message when there is no projects', (done) => {
    const vm = mountComponent(AddGitlabSlackApplication, {
      ...DEFAULT_PROPS,
      projects: [],
      isSignedIn: true,
    });

    vm.popupOpen = true;

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.js-no-projects').textContent)
          .toMatch("You don't have any projects available.");
      })
      .then(done)
      .catch(done.fail);
  });

  it('popup has a sign in link when logged out', (done) => {
    const vm = mountComponent(AddGitlabSlackApplication, {
      ...DEFAULT_PROPS,
    });

    vm.popupOpen = true;
    vm.selectedProjectId = 4;

    vm.$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.js-gitlab-slack-sign-in-link').href)
          .toMatch(new RegExp(signInPath, 'i'));
      })
      .then(done)
      .catch(done.fail);
  });

  it('redirects user to external link when submitted', (done) => {
    const vm = mountComponent(AddGitlabSlackApplication, {
      ...DEFAULT_PROPS,
      isSignedIn: true,
    });
    const addToSlackPromise = Promise.resolve({ data: { add_to_slack_link: redirectLink } });

    spyOn(GitlabSlackService, 'addToSlack').and.returnValue(addToSlackPromise);
    const redirectTo = spyOnDependency(addGitlabSlackApplication, 'redirectTo');

    vm.popupOpen = true;

    vm.$nextTick()
      .then(() => vm.$el.querySelector('.js-add-button').click())
      .then(vm.$nextTick)
      .then(addToSlackPromise)
      .then(() => expect(redirectTo).toHaveBeenCalledWith(redirectLink))
      .then(done)
      .catch(done.fail);
  });
});
