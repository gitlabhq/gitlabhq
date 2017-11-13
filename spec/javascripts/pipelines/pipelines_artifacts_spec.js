import Vue from 'vue';
import artifactsComp from '~/pipelines/components/pipelines_artifacts.vue';

describe('Pipelines Artifacts dropdown', () => {
  let component;
  let artifacts;

  beforeEach(() => {
    const ArtifactsComponent = Vue.extend(artifactsComp);

    artifacts = [
      {
        name: 'artifact',
        path: '/download/path',
      },
    ];

    component = new ArtifactsComponent({
      propsData: {
        artifacts,
      },
    }).$mount();
  });

  it('should render a dropdown with the provided artifacts', () => {
    expect(
      component.$el.querySelectorAll('.dropdown-menu li').length,
    ).toEqual(artifacts.length);
  });

  it('should render a link with the provided path', () => {
    expect(
      component.$el.querySelector('.dropdown-menu li a').getAttribute('href'),
    ).toEqual(artifacts[0].path);

    expect(
      component.$el.querySelector('.dropdown-menu li a').textContent,
    ).toContain(artifacts[0].name);
  });
});
