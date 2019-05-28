import Vue from 'vue';
import formComponent from '~/issue_show/components/form.vue';
import eventHub from '~/issue_show/event_hub';

describe('Inline edit form component', () => {
  let vm;
  let autosave;
  let autosaveObj;

  beforeEach(done => {
    autosaveObj = { reset: jasmine.createSpy() };

    autosave = spyOnDependency(formComponent, 'Autosave').and.returnValue(autosaveObj);

    const Component = Vue.extend(formComponent);

    vm = new Component({
      propsData: {
        canDestroy: true,
        formState: {
          title: 'b',
          description: 'a',
          lockedWarningVisible: false,
        },
        issuableType: 'issue',
        markdownPreviewPath: '/',
        markdownDocsPath: '/',
        projectPath: '/',
        projectNamespace: '/',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('does not render template selector if no templates exist', () => {
    expect(vm.$el.querySelector('.js-issuable-selector-wrap')).toBeNull();
  });

  it('renders template selector when templates exists', done => {
    vm.issuableTemplates = ['test'];

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.js-issuable-selector-wrap')).not.toBeNull();

      done();
    });
  });

  it('hides locked warning by default', () => {
    expect(vm.$el.querySelector('.alert')).toBeNull();
  });

  it('shows locked warning if formState is different', done => {
    vm.formState.lockedWarningVisible = true;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.alert')).not.toBeNull();

      done();
    });
  });

  it('initialized Autosave on mount', () => {
    expect(autosave).toHaveBeenCalledTimes(2);
  });

  it('calls reset on autosave when eventHub emits appropriate events', () => {
    eventHub.$emit('close.form');

    expect(autosaveObj.reset).toHaveBeenCalledTimes(2);

    eventHub.$emit('delete.issuable');

    expect(autosaveObj.reset).toHaveBeenCalledTimes(4);

    eventHub.$emit('update.issuable');

    expect(autosaveObj.reset).toHaveBeenCalledTimes(6);
  });
});
