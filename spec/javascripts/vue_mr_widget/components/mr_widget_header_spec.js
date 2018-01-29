import Vue from 'vue';
import headerComponent from '~/vue_merge_request_widget/components/mr_widget_header';

const createComponent = (mr) => {
  const Component = Vue.extend(headerComponent);
  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetHeader', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = headerComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('computed', () => {
    let vm;
    beforeEach(() => {
      vm = createComponent({
        divergedCommitsCount: 12,
        sourceBranch: 'mr-widget-refactor',
        sourceBranchLink: '/foo/bar/mr-widget-refactor',
        targetBranch: 'master',
      });
    });

    it('shouldShowCommitsBehindText', () => {
      expect(vm.shouldShowCommitsBehindText).toBeTruthy();

      vm.mr.divergedCommitsCount = 0;
      expect(vm.shouldShowCommitsBehindText).toBeFalsy();
    });

    it('commitsText', () => {
      expect(vm.commitsText).toEqual('commits');

      vm.mr.divergedCommitsCount = 1;
      expect(vm.commitsText).toEqual('commit');
    });
  });

  describe('template', () => {
    let vm;
    let el;
    let mr;
    const sourceBranchPath = '/foo/bar/mr-widget-refactor';

    beforeEach(() => {
      mr = {
        divergedCommitsCount: 12,
        sourceBranch: 'mr-widget-refactor',
        sourceBranchLink: `<a href="${sourceBranchPath}">mr-widget-refactor</a>`,
        sourceBranchRemoved: false,
        targetBranchPath: 'foo/bar/commits-path',
        targetBranchTreePath: 'foo/bar/tree/path',
        targetBranch: 'master',
        isOpen: true,
        emailPatchesPath: '/mr/email-patches',
        plainDiffPath: '/mr/plainDiffPath',
      };

      vm = createComponent(mr);
      el = vm.$el;
    });

    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-source-target')).toBeTruthy();
      const sourceBranchLink = el.querySelectorAll('.label-branch')[0];
      const targetBranchLink = el.querySelectorAll('.label-branch')[1];
      const commitsCount = el.querySelector('.diverged-commits-count');

      expect(sourceBranchLink.textContent).toContain(mr.sourceBranch);
      expect(targetBranchLink.textContent).toContain(mr.targetBranch);
      expect(sourceBranchLink.querySelector('a').getAttribute('href')).toEqual(sourceBranchPath);
      expect(targetBranchLink.querySelector('a').getAttribute('href')).toEqual(mr.targetBranchTreePath);
      expect(commitsCount.textContent).toContain('12 commits behind');
      expect(commitsCount.querySelector('a').getAttribute('href')).toEqual(mr.targetBranchPath);

      expect(el.textContent).toContain('Check out branch');
      expect(el.querySelectorAll('.dropdown li a')[0].getAttribute('href')).toEqual(mr.emailPatchesPath);
      expect(el.querySelectorAll('.dropdown li a')[1].getAttribute('href')).toEqual(mr.plainDiffPath);

      expect(el.querySelector('a[href="#modal_merge_info"]').getAttribute('disabled')).toBeNull();
    });

    it('should not have right action links if the MR state is not open', (done) => {
      vm.mr.isOpen = false;
      Vue.nextTick(() => {
        expect(el.textContent).not.toContain('Check out branch');
        expect(el.querySelectorAll('.dropdown li a').length).toEqual(0);
        done();
      });
    });

    it('should not render diverged commits count if the MR has no diverged commits', (done) => {
      vm.mr.divergedCommitsCount = null;
      Vue.nextTick(() => {
        expect(el.textContent).not.toContain('commits behind');
        expect(el.querySelectorAll('.diverged-commits-count').length).toEqual(0);
        done();
      });
    });

    it('should disable check out branch button if source branch has been removed', (done) => {
      vm.mr.sourceBranchRemoved = true;

      Vue.nextTick()
        .then(() => {
          expect(el.querySelector('a[href="#modal_merge_info"]').getAttribute('disabled')).toBe('disabled');
          done();
        })
        .catch(done.fail);
    });
  });
});
