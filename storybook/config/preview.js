const stylesheetsRequireCtx = require.context(
  '../../app/assets/stylesheets',
  true,
  /application\.scss$/,
);

stylesheetsRequireCtx('./application.scss');
