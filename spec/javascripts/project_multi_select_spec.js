import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import projectMultiSelect from '~/project_multi_select';
import Api from '~/api';

const FIXTURE_PATH = 'static/project_multi_select.html.raw';
const TEST_PROJECTS = [
  {
    id: 1,
    name: 'Lorem',
  },
  {
    id: 2,
    name: 'Ipsum',
  },
  {
    id: 3,
    name: 'Dolar',
  },
  {
    id: 4,
    name: 'Sit',
  },
];

describe('project_multi_select', () => {
  preloadFixtures(FIXTURE_PATH);

  let mock;
  let $input;
  let projectsResponse;

  beforeEach(() => {
    loadFixtures(FIXTURE_PATH);

    $input = $('#project_ids');

    mock = new MockAdapter(axios);
    mock.onGet(Api.buildUrl(Api.projectsPath))
      .reply(() => projectsResponse);

    projectsResponse = new Promise(() => {});
  });

  afterEach(() => {
    mock.restore();
  });

  describe('projectMultiSelect', () => {
    let $iconContainer;

    beforeEach(() => {
      projectMultiSelect();

      $iconContainer = $input.parents('.input-icon-wrapper').first();
    });

    it('comma separates values', () => {
      const vals = ['1', '2', '7'];

      $input.val(vals);

      expect($input.val().split(',')).toEqual(vals);
    });

    it('hides icon on open', () => {
      $input.select2('open');

      expect($iconContainer).toHaveClass('hide-input-icon');
    });

    it('shows icon on close', () => {
      $input.select2('open');
      $input.select2('close');

      expect($iconContainer).not.toHaveClass('hide-input-icon');
    });

    it('queries and displays projects', (done) => {
      projectsResponse = Promise.resolve([200, TEST_PROJECTS]);

      $input.one('select2-loaded', () => {
        const projectTitles = $('#select2-drop')
          .find('.frequent-items-item-title')
          .toArray()
          .map(x => x.textContent);

        expect(projectTitles).toEqual(TEST_PROJECTS.map(x => x.name));

        done();
      });

      $input.select2('open');
    });
  });
});
