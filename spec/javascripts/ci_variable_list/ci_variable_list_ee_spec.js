import VariableList from '~/ci_variable_list/ci_variable_list';
import getSetTimeoutPromise from '../helpers/set_timeout_promise_helper';

describe('VariableList (EE features)', () => {
  let $wrapper;
  let variableList;

  describe('with all inputs(key, value, protected, environment)', () => {
    beforeEach(() => {
      // This markup will be replaced with a fixture when we can render the
      // CI/CD settings page with the new dynamic variable list in https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/4110
      $wrapper = $(`<form class="js-variable-list">
        <ul>
          <li class="js-row">
            <div class="ci-variable-body-item">
              <input class="js-ci-variable-input-key" name="variables[variables_attributes][][key]">
            </div>

            <div class="ci-variable-body-item">
              <textarea class="js-ci-variable-input-value" name="variables[variables_attributes][][value]"></textarea>
            </div>

            <div class="ci-variable-body-item ci-variable-protected-item">
              <button type="button" class="js-project-feature-toggle project-feature-toggle">
                <input
                  type="hidden"
                  class="js-ci-variable-input-protected js-project-feature-toggle-input"
                  name="variables[variables_attributes][][protected]"
                  value="true"
                />
              </button>
            </div>

            <div class="ci-variable-body-item">
              <input type="hidden" name="variables[variables_attributes][][environment]" value="*" />
              <div class="dropdown js-variable-environment-dropdown-wrapper">
                <button
                  type="button"
                  class="dropdown-menu-toggle js-variable-environment-toggle"
                  data-toggle="dropdown"
                >
                  <span class="dropdown-toggle-text js-dropdown-toggle-text"></span>
                </button>
                <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
                  <div class="dropdown-input has-value">
                    <input type="search" class="dropdown-input-field js-dropdown-input-field">
                    <button class="dropdown-input-clear js-dropdown-input-clear">
                      Clear search
                    </button>
                  </div>
                  <div class="dropdown-content js-dropdown-content"></div>
                  <div class="dropdown-footer">
                    <ul class="dropdown-footer-list">
                      <li>
                        <button class="dropdown-create-new-item-button js-dropdown-create-new-item">
                          Create wildcard
                          <code class="js-drodpown-create-new-item-slot"></code>
                        </button>
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>

            <button type="button" class="js-row-remove-button"></button>
          </li>
        </ul>
        <button type="button" class="js-secret-value-reveal-button">
          Reveal values
        </button>
      </form>`);

      variableList = new VariableList({
        container: $wrapper,
        formField: 'variables',
      });
      variableList.init();
    });

    describe('environment dropdown', () => {
      function addRowByNewEnvironment(newEnv) {
        const $row = $wrapper.find('.js-row:last-child');

        // Open the dropdown
        $row.find('.js-variable-environment-toggle').click();

        // Filter for the new item
        $row.find('.js-variable-environment-dropdown-wrapper .dropdown-input-field')
          .val(newEnv)
          .trigger('input');

        // Create the new item
        $row.find('.js-variable-environment-dropdown-wrapper .js-dropdown-create-new-item').click();
      }

      it('should add another row when editing the last rows environment dropdown', (done) => {
        addRowByNewEnvironment('someenv');

        getSetTimeoutPromise()
          .then(() => {
            expect($wrapper.find('.js-row').length).toBe(2);

            // Check for the correct default in the new row
            const $environmentInput = $wrapper.find('.js-row:last-child').find('input[name="variables[variables_attributes][][environment]"]');
            expect($environmentInput.val()).toBe('*');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
