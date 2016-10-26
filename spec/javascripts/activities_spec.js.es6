/*= require js.cookie.js */
/*= require jquery.endless-scroll.js */
/*= require pager */
/*= require activities */

(() => {
  window.gon || (window.gon = {});
  const fixtureTemplate = 'event_filter.html';
  const filters = [
    {
      id: 'all',
    }, {
      id: 'push',
      name: 'push events',
    }, {
      id: 'merged',
      name: 'merge events',
    }, {
      id: 'comments',
    },{
      id: 'team',
    }];

  function getEventName(index) {
    let filter = filters[index];
    return filter.hasOwnProperty('name') ? filter.name : filter.id;
  }

  function getSelector(index) {
    let filter = filters[index];
    return `#${filter.id}_event_filter`
  }

  describe('Activities', () => {
    beforeEach(() => {
      fixture.load(fixtureTemplate);
      new Activities();
    });

    for(let i = 0; i < filters.length; i++) {
      ((i) => {
        describe(`when selecting ${getEventName(i)}`, () => {
          beforeEach(() => {
            $(getSelector(i)).click();
          });

          for(let x = 0; x < filters.length; x++) {
            ((x) => {
              let shouldHighlight = i === x;
              let testName = shouldHighlight ? 'should highlight' : 'should not highlight';

              it(`${testName} ${getEventName(x)}`, () => {
                expect($(getSelector(x)).parent().hasClass('active')).toEqual(shouldHighlight);
              });
            })(x);
          }
        });
      })(i);
    }
  });
})();
