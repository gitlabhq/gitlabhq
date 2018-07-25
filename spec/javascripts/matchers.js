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
        pass: !!matchingIcon,
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
};
