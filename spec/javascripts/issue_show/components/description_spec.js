import $ from 'jquery';
import Vue from 'vue';
import '~/behaviors/markdown/render_gfm';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import Description from '~/issue_show/components/description.vue';

describe('Description component', () => {
  let vm;
  let DescriptionComponent;
  const props = {
    canUpdate: true,
    descriptionHtml: 'test',
    descriptionText: 'test',
    updatedAt: new Date().toString(),
    taskStatus: '',
    updateUrl: gl.TEST_HOST,
  };

  beforeEach(() => {
    DescriptionComponent = Vue.extend(Description);

    if (!document.querySelector('.issuable-meta')) {
      const metaData = document.createElement('div');
      metaData.classList.add('issuable-meta');
      metaData.innerHTML =
        '<div class="flash-container"></div><span id="task_status"></span><span id="task_status_short"></span>';

      document.body.appendChild(metaData);
    }

    vm = mountComponent(DescriptionComponent, props);
  });

  afterEach(() => {
    vm.$destroy();
  });

  afterAll(() => {
    $('.issuable-meta .flash-container').remove();
  });

  it('animates description changes', done => {
    vm.descriptionHtml = 'changed';

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.md').classList.contains('issue-realtime-pre-pulse'),
      ).toBeTruthy();

      setTimeout(() => {
        expect(
          vm.$el.querySelector('.md').classList.contains('issue-realtime-trigger-pulse'),
        ).toBeTruthy();

        done();
      });
    });
  });

  it('opens recaptcha dialog if update rejected as spam', done => {
    let modal;
    const recaptchaChild = vm.$children.find(
      // eslint-disable-next-line no-underscore-dangle
      child => child.$options._componentTag === 'recaptcha-modal',
    );

    recaptchaChild.scriptSrc = '//scriptsrc';

    vm.taskListUpdateSuccess({
      recaptcha_html: '<div class="g-recaptcha">recaptcha_html</div>',
    });

    vm.$nextTick()
      .then(() => {
        modal = vm.$el.querySelector('.js-recaptcha-modal');

        expect(modal.style.display).not.toEqual('none');
        expect(modal.querySelector('.g-recaptcha').textContent).toEqual('recaptcha_html');
        expect(document.body.querySelector('.js-recaptcha-script').src).toMatch('//scriptsrc');
      })
      .then(() => modal.querySelector('.close').click())
      .then(() => vm.$nextTick())
      .then(() => {
        expect(modal.style.display).toEqual('none');
        expect(document.body.querySelector('.js-recaptcha-script')).toBeNull();
      })
      .then(done)
      .catch(done.fail);
  });

  describe('TaskList', () => {
    let TaskList;

    beforeEach(() => {
      vm.$destroy();
      vm = mountComponent(
        DescriptionComponent,
        Object.assign({}, props, {
          issuableType: 'issuableType',
        }),
      );
      TaskList = spyOnDependency(Description, 'TaskList');
    });

    it('re-inits the TaskList when description changed', done => {
      vm.descriptionHtml = 'changed';

      setTimeout(() => {
        expect(TaskList).toHaveBeenCalled();
        done();
      });
    });

    it('does not re-init the TaskList when canUpdate is false', done => {
      vm.canUpdate = false;
      vm.descriptionHtml = 'changed';

      setTimeout(() => {
        expect(TaskList).not.toHaveBeenCalled();
        done();
      });
    });

    it('calls with issuableType dataType', done => {
      vm.descriptionHtml = 'changed';

      setTimeout(() => {
        expect(TaskList).toHaveBeenCalledWith({
          dataType: 'issuableType',
          fieldName: 'description',
          selector: '.detail-page-description',
          onSuccess: jasmine.any(Function),
          onError: jasmine.any(Function),
          lockVersion: 0,
        });

        done();
      });
    });
  });

  describe('taskStatus', () => {
    it('adds full taskStatus', done => {
      vm.taskStatus = '1 of 1';

      setTimeout(() => {
        expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe(
          '1 of 1',
        );

        done();
      });
    });

    it('adds short taskStatus', done => {
      vm.taskStatus = '1 of 1';

      setTimeout(() => {
        expect(document.querySelector('.issuable-meta #task_status_short').textContent.trim()).toBe(
          '1/1 task',
        );

        done();
      });
    });

    it('clears task status text when no tasks are present', done => {
      vm.taskStatus = '0 of 0';

      setTimeout(() => {
        expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe('');

        done();
      });
    });
  });

  it('applies syntax highlighting and math when description changed', done => {
    spyOn(vm, 'renderGFM').and.callThrough();
    spyOn($.prototype, 'renderGFM').and.callThrough();
    vm.descriptionHtml = 'changed';

    Vue.nextTick(() => {
      setTimeout(() => {
        expect(vm.$refs['gfm-content']).toBeDefined();
        expect(vm.renderGFM).toHaveBeenCalled();
        expect($.prototype.renderGFM).toHaveBeenCalled();

        done();
      });
    });
  });

  it('sets data-update-url', () => {
    expect(vm.$el.querySelector('textarea').dataset.updateUrl).toEqual(gl.TEST_HOST);
  });

  describe('taskListUpdateError', () => {
    it('should create flash notification and emit an event to parent', () => {
      const msg =
        'Someone edited this issue at the same time you did. The description has been updated and you will need to make your changes again.';
      spyOn(vm, '$emit');

      vm.taskListUpdateError();

      expect(document.querySelector('.flash-container .flash-text').innerText.trim()).toBe(msg);
      expect(vm.$emit).toHaveBeenCalledWith('taskListUpdateFailed');
    });
  });
});
