import LazyLoader from '~/lazy_loader';

let lazyLoader = null;

describe('LazyLoader', function () {
  preloadFixtures('issues/issue_with_comment.html.raw');

  beforeEach(function () {
    loadFixtures('issues/issue_with_comment.html.raw');
    lazyLoader = new LazyLoader({
      observerNode: 'body',
    });
    // Doing everything that happens normally in onload
    lazyLoader.loadCheck();
  });
  describe('behavior', function () {
    it('should copy value from data-src to src for img 1', function (done) {
      const img = document.querySelectorAll('img[data-src]')[0];
      const originalDataSrc = img.getAttribute('data-src');
      img.scrollIntoView();

      setTimeout(() => {
        expect(img.getAttribute('src')).toBe(originalDataSrc);
        expect(document.getElementsByClassName('js-lazy-loaded').length).toBeGreaterThan(0);
        done();
      }, 100);
    });

    it('should lazy load dynamically added data-src images', function (done) {
      const newImg = document.createElement('img');
      const testPath = '/img/testimg.png';
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(newImg.getAttribute('src')).toBe(testPath);
        expect(document.getElementsByClassName('js-lazy-loaded').length).toBeGreaterThan(0);
        done();
      }, 100);
    });

    it('should not alter normal images', function (done) {
      const newImg = document.createElement('img');
      const testPath = '/img/testimg.png';
      newImg.setAttribute('src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(newImg).not.toHaveClass('js-lazy-loaded');
        done();
      }, 100);
    });
  });
});
