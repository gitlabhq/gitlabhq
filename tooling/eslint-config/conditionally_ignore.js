const IS_EE = require('../../config/helpers/is_ee_env');
const IS_JH = require('../../config/helpers/is_jh_env');

const allPatterns = [
  {
    ignore: !IS_EE,
    pattern: 'ee/**/*.*',
  },
  {
    ignore: !IS_JH,
    pattern: 'jh/**/*.*',
  },
];

const ignorePatterns = allPatterns.filter((x) => x.ignore).map((x) => x.pattern);

module.exports = { ignorePatterns };
