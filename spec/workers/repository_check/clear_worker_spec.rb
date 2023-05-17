# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryCheck::ClearWorker, feature_category: :source_code_management do
  it 'clears repository check columns' do
    project = create(:project)
    project.update_columns(
      last_repository_check_failed: true,
      last_repository_check_at: Time.current
    )

    described_class.new.perform
    project.reload

    expect(project.last_repository_check_failed).to be_nil
    expect(project.last_repository_check_at).to be_nil
  end
end
