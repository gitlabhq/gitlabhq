//= require lib/utils/type_utility
//= require jquery
//= require bootstrap
//= require gl_dropdown
//= require select2
//= require jquery.nicescroll
//= require api
//= require create_label
//= require issuable_context
//= require users_select
//= require labels_select

(() => {
  let saveLabelCount = 0;
  describe('Issue dropdown sidebar', () => {
    fixture.preload('issue_sidebar_label.html');

    beforeEach(() => {
      fixture.load('issue_sidebar_label.html');
      new IssuableContext('{"id":1,"name":"Administrator","username":"root"}');
      new LabelsSelect();

      spyOn(jQuery, 'ajax').and.callFake((req) => {
        const d = $.Deferred();
        let LABELS_DATA = []

        if (req.url === '/root/test/labels.json') {
          for (let i = 0; i < 10; i++) {
            LABELS_DATA.push({id: i, title: `test ${i}`, color: '#5CB85C'});
          }
        } else if (req.url === '/root/test/issues/2.json') {
          let tmp = []
          for (let i = 0; i < saveLabelCount; i++) {
            tmp.push({id: i, title: `test ${i}`, color: '#5CB85C'});
          }
          LABELS_DATA = {labels: tmp};
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

        $('.dropdow-content a').each((i, $link) => {
          if (i < 5) {
            $link.get(0).click();
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

        $('.dropdow-content a').each((i, $link) => {
          if (i < 5) {
            $link.get(0).click();
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

