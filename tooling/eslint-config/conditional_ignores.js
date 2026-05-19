const IS_EE = require('../../config/helpers/is_ee_env');
const IS_JH = require('../../config/helpers/is_jh_env');

const conditionalIgnores = [];
if (!IS_EE) {
  conditionalIgnores.push('ee/**/*.*');
}
if (!IS_JH) {
  conditionalIgnores.push('jh/**/*.*');
}

module.exports = { conditionalIgnores };
