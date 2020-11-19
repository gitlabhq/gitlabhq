/* eslint-disable import/no-commonjs */

const IS_EE = require('../../config/helpers/is_ee_env');

module.exports = IS_EE ? {} : { ignorePatterns: ['ee/**/*.*'] };
