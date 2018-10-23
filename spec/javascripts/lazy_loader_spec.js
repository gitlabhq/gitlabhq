import LazyLoader from '~/lazy_loader';
import { TEST_HOST } from './test_constants';

let lazyLoader = null;

const execImmediately = callback => {
  callback();
};

describe('LazyLoader', function() {
  preloadFixtures('issues/issue_with_comment.html.raw');

  describe('with IntersectionObserver disabled', () => {
    beforeEach(function() {
      loadFixtures('issues/issue_with_comment.html.raw');

      lazyLoader = new LazyLoader({
        observerNode: 'foobar',
      });

      spyOn(LazyLoader, 'supportsIntersectionObserver').and.callFake(() => false);

      spyOn(LazyLoader, 'loadImage').and.callThrough();

      spyOn(window, 'requestAnimationFrame').and.callFake(execImmediately);
      spyOn(window, 'requestIdleCallback').and.callFake(execImmediately);

      // Doing everything that happens normally in onload
      lazyLoader.register();
    });

    afterEach(() => {
      lazyLoader.unregister();
    });

    it('should copy value from data-src to src for img 1', function(done) {
      const img = document.querySelectorAll('img[data-src]')[0];
      const originalDataSrc = img.getAttribute('data-src');
      img.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).toHaveBeenCalled();
        expect(img.getAttribute('src')).toBe(originalDataSrc);
        expect(img).toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should lazy load dynamically added data-src images', function(done) {
      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).toHaveBeenCalled();
        expect(newImg.getAttribute('src')).toBe(testPath);
        expect(newImg).toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should not alter normal images', function(done) {
      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.setAttribute('src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).not.toHaveBeenCalled();
        expect(newImg).not.toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should not load dynamically added pictures if content observer is turned off', done => {
      lazyLoader.stopContentObserver();

      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).not.toHaveBeenCalled();
        expect(newImg).not.toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should load dynamically added pictures if content observer is turned off and on again', done => {
      lazyLoader.stopContentObserver();
      lazyLoader.startContentObserver();

      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).toHaveBeenCalled();
        expect(newImg).toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });
  });

  describe('with IntersectionObserver enabled', () => {
    beforeEach(function() {
      loadFixtures('issues/issue_with_comment.html.raw');

      lazyLoader = new LazyLoader({
        observerNode: 'foobar',
      });

      spyOn(LazyLoader, 'loadImage').and.callThrough();

      spyOn(window, 'requestAnimationFrame').and.callFake(execImmediately);
      spyOn(window, 'requestIdleCallback').and.callFake(execImmediately);

      // Doing everything that happens normally in onload
      lazyLoader.register();
    });

    afterEach(() => {
      lazyLoader.unregister();
    });

    it('should copy value from data-src to src for img 1', function(done) {
      const img = document.querySelectorAll('img[data-src]')[0];
      const originalDataSrc = img.getAttribute('data-src');
      img.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).toHaveBeenCalled();
        expect(img.getAttribute('src')).toBe(originalDataSrc);
        expect(img).toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should lazy load dynamically added data-src images', function(done) {
      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).toHaveBeenCalled();
        expect(newImg.getAttribute('src')).toBe(testPath);
        expect(newImg).toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should not alter normal images', function(done) {
      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.setAttribute('src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).not.toHaveBeenCalled();
        expect(newImg).not.toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should not load dynamically added pictures if content observer is turned off', done => {
      lazyLoader.stopContentObserver();

      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).not.toHaveBeenCalled();
        expect(newImg).not.toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });

    it('should load dynamically added pictures if content observer is turned off and on again', done => {
      lazyLoader.stopContentObserver();
      lazyLoader.startContentObserver();

      const newImg = document.createElement('img');
      const testPath = `${TEST_HOST}/img/testimg.png`;
      newImg.className = 'lazy';
      newImg.setAttribute('data-src', testPath);
      document.body.appendChild(newImg);
      newImg.scrollIntoView();

      setTimeout(() => {
        expect(LazyLoader.loadImage).toHaveBeenCalled();
        expect(newImg).toHaveClass('js-lazy-loaded');
        done();
      }, 50);
    });
  });
});
