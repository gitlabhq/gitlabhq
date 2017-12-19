/* eslint-disable no-new */
import IssuableContext from '~/issuable_context';
import LabelsSelect from '~/labels_select';

import '~/commons/gl_dropdown';
import 'select2';
import '~/api';
import '~/create_label';
import '~/users_select';

(() => {
  let saveLabelCount = 0;
  describe('Issue dropdown sidebar', () => {
    preloadFixtures('static/issue_sidebar_label.html.raw');

    beforeEach(() => {
      loadFixtures('static/issue_sidebar_label.html.raw');
      new IssuableContext('{"id":1,"name":"Administrator","username":"root"}');
      new LabelsSelect();

      spyOn(jQuery, 'ajax').and.callFake((req) => {
        const d = $.Deferred();
        let LABELS_DATA = [];

        if (req.url === '/root/test/labels.json') {
          for (let i = 0; i < 10; i += 1) {
            LABELS_DATA.push({ id: i, title: `test ${i}`, color: '#5CB85C' });
          }
        } else if (req.url === '/root/test/issues/2.json') {
          const tmp = [];
          for (let i = 0; i < saveLabelCount; i += 1) {
            tmp.push({ id: i, title: `test ${i}`, color: '#5CB85C' });
          }
          LABELS_DATA = { labels: tmp };
        }

        d.resolve(LABELS_DATA);
        return d.promise();
      });
    });

    it('changes collapsed tooltip when changing labels when less than 5', (done) => {
      saveLabelCount = 5;
      $('.edit-link').get(0).click();

      setTimeout(() => {
        expect($('.dropdown-content a').length).toBe(10);

        $('.dropdown-content a').each(function (i) {
          if (i < saveLabelCount) {
            $(this).get(0).click();
          }
        });

        $('.edit-link').get(0).click();

        setTimeout(() => {
          expect($('.sidebar-collapsed-icon').attr('data-original-title')).toBe('test 0, test 1, test 2, test 3, test 4');
          done();
        }, 0);
      }, 0);
    });

    it('changes collapsed tooltip when changing labels when more than 5', (done) => {
      saveLabelCount = 6;
      $('.edit-link').get(0).click();

      setTimeout(() => {
        expect($('.dropdown-content a').length).toBe(10);

        $('.dropdown-content a').each(function (i) {
          if (i < saveLabelCount) {
            $(this).get(0).click();
          }
        });

        $('.edit-link').get(0).click();

        setTimeout(() => {
          expect($('.sidebar-collapsed-icon').attr('data-original-title')).toBe('test 0, test 1, test 2, test 3, test 4, and 1 more');
          done();
        }, 0);
      }, 0);
    });
  });
})();
