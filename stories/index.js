window.gon = window.gon || {};
window.gon.current_user_id = 1;

window.describe = () => {};

// gl global stuff that isn't imported
import '../app/assets/javascripts/lib/utils/datetime_utility';
import '../app/assets/javascripts/lib/utils/common_utils';
import '../app/assets/javascripts/commons/bootstrap';
import '../app/assets/javascripts/flash';

import './mr_widget_story';
import './mr_widget_header_story';
import './mr_widget_states_story';
import './mr_widget_pipeline_story';
import './mr_widget_deployment_story';

try {
  require('./ee');
} catch(e) {
  // no ee
}
