/* eslint-disable no-new */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import IssuableContext from '~/issuable_context';
import LabelsSelect from '~/labels_select';

import '~/gl_dropdown';
import 'select2';
import '~/api';
import '~/create_label';
import '~/users_select';

let saveLabelCount = 0;
let mock;

function testLabelClicks(labelOrder, done) {
  $('.edit-link')
    .get(0)
    .click();

  setTimeout(() => {
    const labelsInDropdown = $('.dropdown-content a');

    expect(labelsInDropdown.length).toBe(10);

    const arrayOfLabels = labelsInDropdown.get();
    const randomArrayOfLabels = _.shuffle(arrayOfLabels);
    randomArrayOfLabels.forEach((label, i) => {
      if (i < saveLabelCount) {
        $(label).click();
      }
    });

    $('.edit-link')
      .get(0)
      .click();

    setTimeout(() => {
      expect($('.sidebar-collapsed-icon').attr('data-original-title')).toBe(labelOrder);
      done();
    }, 0);
  }, 0);
}

describe('Issue dropdown sidebar', () => {
  preloadFixtures('static/issue_sidebar_label.html');

  beforeEach(() => {
    loadFixtures('static/issue_sidebar_label.html');

    mock = new MockAdapter(axios);

    new IssuableContext('{"id":1,"name":"Administrator","username":"root"}');
    new LabelsSelect();

    mock.onGet('/root/test/labels.json').reply(() => {
      const labels = Array(10)
        .fill()
        .map((_val, i) => ({
          id: i,
          title: `test ${i}`,
          color: '#5CB85C',
        }));

      return [200, labels];
    });

    mock.onPut('/root/test/issues/2.json').reply(() => {
      const labels = Array(saveLabelCount)
        .fill()
        .map((_val, i) => ({
          id: i,
          title: `test ${i}`,
          color: '#5CB85C',
        }));

      return [200, { labels }];
    });
  });

  afterEach(() => {
    mock.restore();
  });

  it('changes collapsed tooltip when changing labels when less than 5', done => {
    saveLabelCount = 5;
    testLabelClicks('test 0, test 1, test 2, test 3, test 4', done);
  });

  it('changes collapsed tooltip when changing labels when more than 5', done => {
    saveLabelCount = 6;
    testLabelClicks('test 0, test 1, test 2, test 3, test 4, and 1 more', done);
  });
});
