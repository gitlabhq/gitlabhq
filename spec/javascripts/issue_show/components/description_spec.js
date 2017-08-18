import Vue from 'vue';
import descriptionComponent from '~/issue_show/components/description.vue';

describe('Description component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(descriptionComponent);

    if (!document.querySelector('.issuable-meta')) {
      const metaData = document.createElement('div');
      metaData.classList.add('issuable-meta');
      metaData.innerHTML = '<span id="task_status"></span><span id="task_status_short"></span>';

      document.body.appendChild(metaData);
    }

    vm = new Component({
      propsData: {
        canUpdate: true,
        descriptionHtml: 'test',
        descriptionText: 'test',
        updatedAt: new Date().toString(),
        taskStatus: '',
      },
    }).$mount();
  });

  it('animates description changes', (done) => {
    vm.descriptionHtml = 'changed';

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('.wiki').classList.contains('issue-realtime-pre-pulse'),
      ).toBeTruthy();

      setTimeout(() => {
        expect(
          vm.$el.querySelector('.wiki').classList.contains('issue-realtime-trigger-pulse'),
        ).toBeTruthy();

        done();
      });
    });
  });

  // TODO: gl.TaskList no longer exists. rewrite these tests once we have a way to rewire ES modules

  // it('re-inits the TaskList when description changed', (done) => {
  //   spyOn(gl, 'TaskList');
  //   vm.descriptionHtml = 'changed';
  //
  //   setTimeout(() => {
  //     expect(
  //       gl.TaskList,
  //     ).toHaveBeenCalled();
  //
  //     done();
  //   });
  // });

  // it('does not re-init the TaskList when canUpdate is false', (done) => {
  //   spyOn(gl, 'TaskList');
  //   vm.canUpdate = false;
  //   vm.descriptionHtml = 'changed';
  //
  //   setTimeout(() => {
  //     expect(
  //       gl.TaskList,
  //     ).not.toHaveBeenCalled();
  //
  //     done();
  //   });
  // });

  describe('taskStatus', () => {
    it('adds full taskStatus', (done) => {
      vm.taskStatus = '1 of 1';

      setTimeout(() => {
        expect(
          document.querySelector('.issuable-meta #task_status').textContent.trim(),
        ).toBe('1 of 1');

        done();
      });
    });

    it('adds short taskStatus', (done) => {
      vm.taskStatus = '1 of 1';

      setTimeout(() => {
        expect(
          document.querySelector('.issuable-meta #task_status_short').textContent.trim(),
        ).toBe('1/1 task');

        done();
      });
    });

    it('clears task status text when no tasks are present', (done) => {
      vm.taskStatus = '0 of 0';

      setTimeout(() => {
        expect(
          document.querySelector('.issuable-meta #task_status').textContent.trim(),
        ).toBe('');

        done();
      });
    });
  });

  it('applies syntax highlighting and math when description changed', (done) => {
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
});
