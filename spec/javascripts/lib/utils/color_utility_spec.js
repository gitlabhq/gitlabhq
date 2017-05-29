import { hsvToRgb, degreesToRadians, rgbToHsv } from '~/lib/utils/color_utils';

describe('Color Utilities', () => {
  describe('Convert a HSV color space to RGB', () => {
    this.hue = 0.7106712538596932;
    this.sat = 0.4;
    this.val = 0.95;

    it('Returns the (converted) value/brightness as RGB when no saturation is provided', () => {
      const rgbColor = hsvToRgb(this.hue, 0, this.val);
      const expectedColor = parseInt(this.val * 256, 10);
      rgbColor.forEach((color) => {
        expect(color).toEqual(expectedColor);
      });
    });

    it('sets the (converted) val/brightness to the blue color', () => {
      const rgbColor = hsvToRgb(this.hue, this.sat, this.val);
      const expectedColor = parseInt(this.val * 256, 10);
      expect(rgbColor[2]).toEqual(expectedColor);
    });

    it('returns rgb colors between 0 and 255', () => {
      const rgbColor = hsvToRgb(this.hue, this.sat, this.val);
      rgbColor.forEach((color) => {
        expect(color).not.toBeLessThan(0);
        expect(color).toBeGreaterThan(0);
        expect(color).toBeLessThan(255);
        expect(color).not.toBeGreaterThan(255);
      });
    });
  });

  describe('Converts degrees to radians', () => {
    it('returns a 0 when the parameter provided is not a number', () => {
      const rads = degreesToRadians('not a number');
      expect(rads).toEqual(0);
    });
  });

  describe('Converts an RGB color to a HSV', () => {
    it('returns the hue as 0 when the the max and min color values are the same', () => {
      const hsvColor = rgbToHsv([200, 200, 200]);
      expect(hsvColor[0]).toEqual(0);
    });

    it('returns the saturation as 0 when the the max color value is 0', () => {
      const hsvColor = rgbToHsv([0, 0, 0]);
      expect(hsvColor[1]).toEqual(0);
    });

    it('returns a hsv color space that ranges between 0 and 1', () => {
      const hsvColor = rgbToHsv([237, 240, 210]);
      hsvColor.forEach((el) => {
        expect(el).not.toBeLessThan(0);
        expect(el).toBeGreaterThan(0);
        expect(el).toBeLessThan(1);
        expect(el).not.toBeGreaterThan(1);
      });
    });
  });
});
