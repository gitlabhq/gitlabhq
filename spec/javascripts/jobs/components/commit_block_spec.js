import Vue from 'vue';
import component from '~/jobs/components/commit_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Commit block', () => {
  const Component = Vue.extend(component);
  let vm;

  const props = {
    pipelineShortSha: '1f0fb84f',
    pipelineShaPath: 'commit/1f0fb84fb6770d74d97eee58118fd3909cd4f48c',
    mergeRequestReference: '!21244',
    mergeRequestPath: 'merge_requests/21244',
    gitCommitTitlte: 'Regenerate pot files',
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('pipeline short sha', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...props,
      });
    });

    it('renders pipeline short sha link', () => {
      expect(vm.$el.querySelector('.js-commit-sha').getAttribute('href')).toEqual(props.pipelineShaPath);
      expect(vm.$el.querySelector('.js-commit-sha').textContent.trim()).toEqual(props.pipelineShortSha);
    });

    it('renders clipboard button', () => {
      expect(vm.$el.querySelector('button').getAttribute('data-clipboard-text')).toEqual(props.pipelineShortSha);
    });
  });

  describe('with merge request', () => {
    it('renders merge request link and reference', () => {
      vm = mountComponent(Component, {
        ...props,
      });

      expect(vm.$el.querySelector('.js-link-commit').getAttribute('href')).toEqual(props.mergeRequestPath);
      expect(vm.$el.querySelector('.js-link-commit').textContent.trim()).toEqual(props.mergeRequestReference);

    });
  });

  describe('without merge request', () => {
    it('does not render merge request', () => {
      const copyProps = Object.assign({}, props);
      delete copyProps.mergeRequestPath;
      delete copyProps.mergeRequestReference;

      vm = mountComponent(Component, {
        ...copyProps,
      });

      expect(vm.$el.querySelector('.js-link-commit')).toBeNull();
    });
  });

  describe('git commit title', () => {
    it('renders git commit title', () => {
      vm = mountComponent(Component, {
        ...props,
      });

      expect(vm.$el.textContent).toContain(props.gitCommitTitlte);
    });
  });
});
