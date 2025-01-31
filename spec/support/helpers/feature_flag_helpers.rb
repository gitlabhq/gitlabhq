# frozen_string_literal: true

module FeatureFlagHelpers
  def create_flag(project, name, active = true, description: nil, version: Operations::FeatureFlag.versions['new_version_flag'])
    create(
      :operations_feature_flag,
      name: name,
      active: active,
      version: version,
      description: description,
      project: project
    )
  end

  def create_scope(feature_flag, environment_scope, active = true, strategies = [{ name: "default", parameters: {} }])
    create(
      :operations_feature_flag_scope,
      feature_flag: feature_flag,
      environment_scope: environment_scope,
      active: active,
      strategies: strategies
    )
  end

  def create_strategy(feature_flag, name = 'default', parameters = {})
    create(
      :operations_strategy,
      feature_flag: feature_flag,
      name: name
    )
  end

  def within_feature_flag_row(index)
    within "tbody tr:nth-child(#{index})" do
      yield
    end
  end

  def within_feature_flag_scopes
    within "div[data-testid='feature-flag-environments']" do
      yield
    end
  end

  def within_scope_row(index)
    within "tbody tr:nth-child(#{index + 1})" do
      yield
    end
  end

  def within_strategy_row(index)
    within ".feature-flags-form > fieldset > div[data-testid='feature-flag-strategies'] > div:nth-child(#{index})" do
      yield
    end
  end

  def within_environment_spec
    within '.table-section:nth-child(1)' do
      yield
    end
  end

  def within_status
    within '.table-section:nth-child(2)' do
      yield
    end
  end

  def within_delete
    within '.table-section:nth-child(4)' do
      yield
    end
  end

  def edit_feature_flag_button
    find_link 'Edit'
  end

  def delete_strategy_button
    find("button[data-testid='delete-strategy-button']")
  end

  def add_linked_issue_button
    find_button 'Add a related issue'
  end

  def remove_linked_issue_button
    find('.js-issue-item-remove-button')
  end

  def status_toggle_button
    find('[data-testid="feature-flag-status-toggle"] button')
  end

  def expect_status_toggle_button_to_be_checked
    expect(page).to have_css('[data-testid="feature-flag-status-toggle"] button.is-checked')
  end

  def expect_status_toggle_button_not_to_be_checked
    expect(page).to have_css('[data-testid="feature-flag-status-toggle"] button:not(.is-checked)')
  end

  def expect_status_toggle_button_to_be_disabled
    expect(page).to have_css('[data-testid="feature-flag-status-toggle"] button.is-disabled')
  end

  def expect_user_to_see_feature_flags_index_page
    expect(page).to have_text('Feature flags')
  end
end
