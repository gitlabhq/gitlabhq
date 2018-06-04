/* eslint-disable no-new, promise/catch-or-return */
import JSZip from 'jszip';
import SketchLoader from '~/blob/sketch';

describe('Sketch viewer', () => {
  const generateZipFileArrayBuffer = (zipFile, resolve, done) => {
    zipFile
      .generateAsync({ type: 'arrayBuffer' })
      .then((content) => {
        resolve(content);

        setTimeout(() => {
          done();
        }, 100);
      });
  };

  preloadFixtures('static/sketch_viewer.html.raw');

  beforeEach(() => {
    loadFixtures('static/sketch_viewer.html.raw');
  });

  describe('with error message', () => {
    beforeEach((done) => {
      spyOn(SketchLoader.prototype, 'getZipFile').and.callFake(() => new Promise((resolve, reject) => {
        reject();

        setTimeout(() => {
          done();
        });
      }));

      new SketchLoader(document.getElementById('js-sketch-viewer'));
    });

    it('renders error message', () => {
      expect(
        document.querySelector('#js-sketch-viewer p'),
      ).not.toBeNull();

      expect(
        document.querySelector('#js-sketch-viewer p').textContent.trim(),
      ).toContain('Cannot show preview.');
    });

    it('removes render the loading icon', () => {
      expect(
        document.querySelector('.js-loading-icon'),
      ).toBeNull();
    });
  });

  describe('success', () => {
    beforeEach((done) => {
      spyOn(SketchLoader.prototype, 'getZipFile').and.callFake(() => new Promise((resolve) => {
        const zipFile = new JSZip();
        zipFile.folder('previews')
          .file('preview.png', 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAMAAAAoyzS7AAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAA1JREFUeNoBAgD9/wAAAAIAAVMrnDAAAAAASUVORK5CYII=', {
            base64: true,
          });

        generateZipFileArrayBuffer(zipFile, resolve, done);
      }));

      new SketchLoader(document.getElementById('js-sketch-viewer'));
    });

    it('does not render error message', () => {
      expect(
        document.querySelector('#js-sketch-viewer p'),
      ).toBeNull();
    });

    it('removes render the loading icon', () => {
      expect(
        document.querySelector('.js-loading-icon'),
      ).toBeNull();
    });

    it('renders preview img', () => {
      const img = document.querySelector('#js-sketch-viewer img');

      expect(img).not.toBeNull();
      expect(img.classList.contains('img-fluid')).toBeTruthy();
    });

    it('renders link to image', () => {
      const img = document.querySelector('#js-sketch-viewer img');
      const link = document.querySelector('#js-sketch-viewer a');

      expect(link.href).toBe(img.src);
      expect(link.target).toBe('_blank');
    });
  });

  describe('incorrect file', () => {
    beforeEach((done) => {
      spyOn(SketchLoader.prototype, 'getZipFile').and.callFake(() => new Promise((resolve) => {
        const zipFile = new JSZip();

        generateZipFileArrayBuffer(zipFile, resolve, done);
      }));

      new SketchLoader(document.getElementById('js-sketch-viewer'));
    });

    it('renders error message', () => {
      expect(
        document.querySelector('#js-sketch-viewer p'),
      ).not.toBeNull();

      expect(
        document.querySelector('#js-sketch-viewer p').textContent.trim(),
      ).toContain('Cannot show preview.');
    });
  });
});
