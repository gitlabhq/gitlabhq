import pixelmatch from 'pixelmatch';

export default {
  toContainText: () => ({
    compare(vm, text) {
      if (!(vm.$el instanceof HTMLElement)) {
        throw new Error('vm.$el is not a DOM element!');
      }

      const result = {
        pass: vm.$el.innerText.includes(text),
      };
      return result;
    },
  }),
  toHaveSpriteIcon: () => ({
    compare(element, iconName) {
      if (!iconName) {
        throw new Error('toHaveSpriteIcon is missing iconName argument!');
      }

      if (!(element instanceof HTMLElement)) {
        throw new Error(`${element} is not a DOM element!`);
      }

      const iconReferences = [].slice.apply(element.querySelectorAll('svg use'));
      const matchingIcon = iconReferences.find(reference =>
        reference.getAttribute('xlink:href').endsWith(`#${iconName}`),
      );
      const result = {
        pass: Boolean(matchingIcon),
      };

      if (result.pass) {
        result.message = `${element.outerHTML} contains the sprite icon "${iconName}"!`;
      } else {
        result.message = `${element.outerHTML} does not contain the sprite icon "${iconName}"!`;

        const existingIcons = iconReferences.map(reference => {
          const iconUrl = reference.getAttribute('xlink:href');
          return `"${iconUrl.replace(/^.+#/, '')}"`;
        });
        if (existingIcons.length > 0) {
          result.message += ` (only found ${existingIcons.join(',')})`;
        }
      }

      return result;
    },
  }),
  toRender: () => ({
    compare(vm) {
      const result = {
        pass: vm.$el.nodeType !== Node.COMMENT_NODE,
      };
      return result;
    },
  }),
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
