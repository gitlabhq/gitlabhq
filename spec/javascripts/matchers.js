import pixelmatch from 'pixelmatch';

export default {
  toImageDiffEqual: () => {
    const getImageData = img => {
      const canvas = document.createElement('canvas');
      canvas.width = img.width;
      canvas.height = img.height;
      canvas.getContext('2d').drawImage(img, 0, 0);
      return canvas.getContext('2d').getImageData(0, 0, img.width, img.height).data;
    };

    return {
      compare(actual, expected, threshold = 0.1) {
        if (actual.height !== expected.height || actual.width !== expected.width) {
          return {
            pass: false,
            message: `Expected image dimensions (h x w) of ${expected.height}x${expected.width}.
            Received an image with ${actual.height}x${actual.width}`,
          };
        }

        const { width, height } = actual;
        const differentPixels = pixelmatch(
          getImageData(actual),
          getImageData(expected),
          null,
          width,
          height,
          { threshold },
        );

        return {
          pass: differentPixels < 20,
          message: `${differentPixels} pixels differ more than ${threshold *
            100} percent between input and output.`,
        };
      },
    };
  },
};
