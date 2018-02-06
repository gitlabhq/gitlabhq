import { glEmojiTag } from '~/emoji';
import isEmojiUnicodeSupported, {
  isFlagEmoji,
  isRainbowFlagEmoji,
  isKeycapEmoji,
  isSkinToneComboEmoji,
  isHorceRacingSkinToneComboEmoji,
  isPersonZwjEmoji,
} from '~/emoji/support/is_emoji_unicode_supported';

const emptySupportMap = {
  personZwj: false,
  horseRacing: false,
  flag: false,
  skinToneModifier: false,
  '9.0': false,
  '8.0': false,
  '7.0': false,
  6.1: false,
  '6.0': false,
  5.2: false,
  5.1: false,
  4.1: false,
  '4.0': false,
  3.2: false,
  '3.0': false,
  1.1: false,
};

const emojiFixtureMap = {
  bomb: {
    name: 'bomb',
    moji: '💣',
    unicodeVersion: '6.0',
  },
  construction_worker_tone5: {
    name: 'construction_worker_tone5',
    moji: '👷🏿',
    unicodeVersion: '8.0',
  },
  five: {
    name: 'five',
    moji: '5️⃣',
    unicodeVersion: '3.0',
  },
  grey_question: {
    name: 'grey_question',
    moji: '❔',
    unicodeVersion: '6.0',
  },
};

function markupToDomElement(markup) {
  const div = document.createElement('div');
  div.innerHTML = markup;
  return div.firstElementChild;
}

function testGlEmojiImageFallback(element, name, src) {
  expect(element.tagName.toLowerCase()).toBe('img');
  expect(element.getAttribute('src')).toBe(src);
  expect(element.getAttribute('title')).toBe(`:${name}:`);
  expect(element.getAttribute('alt')).toBe(`:${name}:`);
}

const defaults = {
  forceFallback: false,
  sprite: false,
};

function testGlEmojiElement(element, name, unicodeVersion, unicodeMoji, options = {}) {
  const opts = Object.assign({}, defaults, options);
  expect(element.tagName.toLowerCase()).toBe('gl-emoji');
  expect(element.dataset.name).toBe(name);
  expect(element.dataset.fallbackSrc.length).toBeGreaterThan(0);
  expect(element.dataset.unicodeVersion).toBe(unicodeVersion);

  const fallbackSpriteClass = `emoji-${name}`;
  if (opts.sprite) {
    expect(element.dataset.fallbackSpriteClass).toBe(fallbackSpriteClass);
  }

  if (opts.forceFallback && opts.sprite) {
    expect(element.getAttribute('class')).toBe(`emoji-icon ${fallbackSpriteClass}`);
  }

  if (opts.forceFallback && !opts.sprite) {
    // Check for image fallback
    testGlEmojiImageFallback(element.firstElementChild, name, element.dataset.fallbackSrc);
  } else {
    // Otherwise make sure things are still unicode text
    expect(element.textContent.trim()).toBe(unicodeMoji);
  }
}

describe('gl_emoji', () => {
  describe('glEmojiTag', () => {
    it('bomb emoji', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiFixtureMap[emojiKey].name);
      const glEmojiElement = markupToDomElement(markup);
      testGlEmojiElement(
        glEmojiElement,
        emojiFixtureMap[emojiKey].name,
        emojiFixtureMap[emojiKey].unicodeVersion,
        emojiFixtureMap[emojiKey].moji,
      );
    });

    it('bomb emoji with image fallback', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiFixtureMap[emojiKey].name, {
        forceFallback: true,
      });
      const glEmojiElement = markupToDomElement(markup);
      testGlEmojiElement(
        glEmojiElement,
        emojiFixtureMap[emojiKey].name,
        emojiFixtureMap[emojiKey].unicodeVersion,
        emojiFixtureMap[emojiKey].moji,
        {
          forceFallback: true,
        },
      );
    });

    it('bomb emoji with sprite fallback readiness', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiFixtureMap[emojiKey].name, {
        sprite: true,
      });
      const glEmojiElement = markupToDomElement(markup);
      testGlEmojiElement(
        glEmojiElement,
        emojiFixtureMap[emojiKey].name,
        emojiFixtureMap[emojiKey].unicodeVersion,
        emojiFixtureMap[emojiKey].moji,
        {
          sprite: true,
        },
      );
    });
    it('bomb emoji with sprite fallback', () => {
      const emojiKey = 'bomb';
      const markup = glEmojiTag(emojiFixtureMap[emojiKey].name, {
        forceFallback: true,
        sprite: true,
      });
      const glEmojiElement = markupToDomElement(markup);
      testGlEmojiElement(
        glEmojiElement,
        emojiFixtureMap[emojiKey].name,
        emojiFixtureMap[emojiKey].unicodeVersion,
        emojiFixtureMap[emojiKey].moji,
        {
          forceFallback: true,
          sprite: true,
        },
      );
    });

    it('question mark when invalid emoji name given', () => {
      const name = 'invalid_emoji';
      const emojiKey = 'grey_question';
      const markup = glEmojiTag(name);
      const glEmojiElement = markupToDomElement(markup);
      testGlEmojiElement(
        glEmojiElement,
        emojiFixtureMap[emojiKey].name,
        emojiFixtureMap[emojiKey].unicodeVersion,
        emojiFixtureMap[emojiKey].moji,
      );
    });

    it('question mark with image fallback when invalid emoji name given', () => {
      const name = 'invalid_emoji';
      const emojiKey = 'grey_question';
      const markup = glEmojiTag(name, {
        forceFallback: true,
      });
      const glEmojiElement = markupToDomElement(markup);
      testGlEmojiElement(
        glEmojiElement,
        emojiFixtureMap[emojiKey].name,
        emojiFixtureMap[emojiKey].unicodeVersion,
        emojiFixtureMap[emojiKey].moji,
        {
          forceFallback: true,
        },
      );
    });
  });

  describe('isFlagEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isFlagEmoji('')).toBeFalsy();
    });
    it('should detect flag_ac', () => {
      expect(isFlagEmoji('🇦🇨')).toBeTruthy();
    });
    it('should detect flag_us', () => {
      expect(isFlagEmoji('🇺🇸')).toBeTruthy();
    });
    it('should detect flag_zw', () => {
      expect(isFlagEmoji('🇿🇼')).toBeTruthy();
    });
    it('should not detect flags', () => {
      expect(isFlagEmoji('🎏')).toBeFalsy();
    });
    it('should not detect triangular_flag_on_post', () => {
      expect(isFlagEmoji('🚩')).toBeFalsy();
    });
    it('should not detect single letter', () => {
      expect(isFlagEmoji('🇦')).toBeFalsy();
    });
    it('should not detect >2 letters', () => {
      expect(isFlagEmoji('🇦🇧🇨')).toBeFalsy();
    });
  });

  describe('isRainbowFlagEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isRainbowFlagEmoji('')).toBeFalsy();
    });
    it('should detect rainbow_flag', () => {
      expect(isRainbowFlagEmoji('🏳🌈')).toBeTruthy();
    });
    it('should not detect flag_white on its\' own', () => {
      expect(isRainbowFlagEmoji('🏳')).toBeFalsy();
    });
    it('should not detect rainbow on its\' own', () => {
      expect(isRainbowFlagEmoji('🌈')).toBeFalsy();
    });
    it('should not detect flag_white with something else', () => {
      expect(isRainbowFlagEmoji('🏳🔵')).toBeFalsy();
    });
  });

  describe('isKeycapEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isKeycapEmoji('')).toBeFalsy();
    });
    it('should detect one(keycap)', () => {
      expect(isKeycapEmoji('1️⃣')).toBeTruthy();
    });
    it('should detect nine(keycap)', () => {
      expect(isKeycapEmoji('9️⃣')).toBeTruthy();
    });
    it('should not detect ten(keycap)', () => {
      expect(isKeycapEmoji('🔟')).toBeFalsy();
    });
    it('should not detect hash(keycap)', () => {
      expect(isKeycapEmoji('#⃣')).toBeFalsy();
    });
  });

  describe('isSkinToneComboEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isSkinToneComboEmoji('')).toBeFalsy();
    });
    it('should detect hand_splayed_tone5', () => {
      expect(isSkinToneComboEmoji('🖐🏿')).toBeTruthy();
    });
    it('should not detect hand_splayed', () => {
      expect(isSkinToneComboEmoji('🖐')).toBeFalsy();
    });
    it('should detect lifter_tone1', () => {
      expect(isSkinToneComboEmoji('🏋🏻')).toBeTruthy();
    });
    it('should not detect lifter', () => {
      expect(isSkinToneComboEmoji('🏋')).toBeFalsy();
    });
    it('should detect rowboat_tone4', () => {
      expect(isSkinToneComboEmoji('🚣🏾')).toBeTruthy();
    });
    it('should not detect rowboat', () => {
      expect(isSkinToneComboEmoji('🚣')).toBeFalsy();
    });
    it('should not detect individual tone emoji', () => {
      expect(isSkinToneComboEmoji('🏻')).toBeFalsy();
    });
  });

  describe('isHorceRacingSkinToneComboEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isHorceRacingSkinToneComboEmoji('')).toBeFalsy();
    });
    it('should detect horse_racing_tone2', () => {
      expect(isHorceRacingSkinToneComboEmoji('🏇🏼')).toBeTruthy();
    });
    it('should not detect horse_racing', () => {
      expect(isHorceRacingSkinToneComboEmoji('🏇')).toBeFalsy();
    });
  });

  describe('isPersonZwjEmoji', () => {
    it('should gracefully handle empty string', () => {
      expect(isPersonZwjEmoji('')).toBeFalsy();
    });
    it('should detect couple_mm', () => {
      expect(isPersonZwjEmoji('👨‍❤️‍👨')).toBeTruthy();
    });
    it('should not detect couple_with_heart', () => {
      expect(isPersonZwjEmoji('💑')).toBeFalsy();
    });
    it('should not detect couplekiss', () => {
      expect(isPersonZwjEmoji('💏')).toBeFalsy();
    });
    it('should detect family_mmb', () => {
      expect(isPersonZwjEmoji('👨‍👨‍👦')).toBeTruthy();
    });
    it('should detect family_mwgb', () => {
      expect(isPersonZwjEmoji('👨‍👩‍👧‍👦')).toBeTruthy();
    });
    it('should not detect family', () => {
      expect(isPersonZwjEmoji('👪')).toBeFalsy();
    });
    it('should detect kiss_ww', () => {
      expect(isPersonZwjEmoji('👩‍❤️‍💋‍👩')).toBeTruthy();
    });
    it('should not detect girl', () => {
      expect(isPersonZwjEmoji('👧')).toBeFalsy();
    });
    it('should not detect girl_tone5', () => {
      expect(isPersonZwjEmoji('👧🏿')).toBeFalsy();
    });
    it('should not detect man', () => {
      expect(isPersonZwjEmoji('👨')).toBeFalsy();
    });
    it('should not detect woman', () => {
      expect(isPersonZwjEmoji('👩')).toBeFalsy();
    });
  });

  describe('isEmojiUnicodeSupported', () => {
    it('should gracefully handle empty string with unicode support', () => {
      const isSupported = isEmojiUnicodeSupported(
        { '1.0': true },
        '',
        '1.0',
      );
      expect(isSupported).toBeTruthy();
    });
    it('should gracefully handle empty string without unicode support', () => {
      const isSupported = isEmojiUnicodeSupported(
        {},
        '',
        '1.0',
      );
      expect(isSupported).toBeFalsy();
    });
    it('bomb(6.0) with 6.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = Object.assign({}, emptySupportMap, {
        '6.0': true,
      });
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );
      expect(isSupported).toBeTruthy();
    });

    it('bomb(6.0) without 6.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = emptySupportMap;
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );
      expect(isSupported).toBeFalsy();
    });

    it('bomb(6.0) without 6.0 but with 9.0 support', () => {
      const emojiKey = 'bomb';
      const unicodeSupportMap = Object.assign({}, emptySupportMap, {
        '9.0': true,
      });
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );
      expect(isSupported).toBeFalsy();
    });

    it('construction_worker_tone5(8.0) without skin tone modifier support', () => {
      const emojiKey = 'construction_worker_tone5';
      const unicodeSupportMap = Object.assign({}, emptySupportMap, {
        skinToneModifier: false,
        '9.0': true,
        '8.0': true,
        '7.0': true,
        6.1: true,
        '6.0': true,
        5.2: true,
        5.1: true,
        4.1: true,
        '4.0': true,
        3.2: true,
        '3.0': true,
        1.1: true,
      });
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );
      expect(isSupported).toBeFalsy();
    });

    it('use native keycap on >=57 chrome', () => {
      const emojiKey = 'five';
      const unicodeSupportMap = Object.assign({}, emptySupportMap, {
        '3.0': true,
        meta: {
          isChrome: true,
          chromeVersion: 57,
        },
      });
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );
      expect(isSupported).toBeTruthy();
    });

    it('fallback keycap on <57 chrome', () => {
      const emojiKey = 'five';
      const unicodeSupportMap = Object.assign({}, emptySupportMap, {
        '3.0': true,
        meta: {
          isChrome: true,
          chromeVersion: 50,
        },
      });
      const isSupported = isEmojiUnicodeSupported(
        unicodeSupportMap,
        emojiFixtureMap[emojiKey].moji,
        emojiFixtureMap[emojiKey].unicodeVersion,
      );
      expect(isSupported).toBeFalsy();
    });
  });
});
