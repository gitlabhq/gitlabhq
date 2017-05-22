import Vue from 'vue';
import projectMove from '~/issue_show/components/fields/project_move.vue';

describe('Project move field component', () => {
  let vm;
  let formState;

  beforeEach((done) => {
    const Component = Vue.extend(projectMove);

    formState = {
      move_to_project_id: 0,
    };

    vm = new Component({
      propsData: {
        formState,
        projectsAutocompleteUrl: '/autocomplete',
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('mounts select2 element', () => {
    expect(
      vm.$el.querySelector('.select2-container'),
    ).not.toBeNull();
  });

  it('updates formState on change', () => {
    $(vm.$refs['move-dropdown']).val(2).trigger('change');

    expect(
      formState.move_to_project_id,
    ).toBe(2);
  });
});
