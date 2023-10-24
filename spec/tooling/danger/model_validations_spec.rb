# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/model_validations'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ModelValidations, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }

  subject(:model_validations) { fake_danger.new(helper: fake_helper) }

  before do
    allow(model_validations).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#add_comment_for_added_validations' do
    let(:file_lines) { file_diff.map { |line| line.delete_prefix('+').delete_prefix('-') } }
    let(:filename) { 'app/models/user.rb' }
    let(:added_filename) { 'app/models/user.rb' }

    before do
      allow(model_validations.project_helper).to receive(:file_lines).and_return(file_lines)
      allow(model_validations.helper).to receive(:added_files).and_return([added_filename])
      allow(model_validations.helper).to receive(:modified_files).and_return([filename])
      allow(model_validations.helper).to receive(:changed_lines).with(filename).and_return(file_diff)
    end

    context 'when model has a newly added validation' do
      let(:file_diff) do
        [
          "+ scope :admins, -> { where(admin: true) }",
          "+ validates :name, presence: true, length: { maximum: 255 }",
          "+ validates_with UserValidator",
          "+ validate :check_password_weakness",
          "+ validates_each :restricted_visibility_levels do |record, attr, value|",
          "+ validates_associated :members",
          "+ with_options if: :is_admin? do |admin|",
          "+   admin.validates :password, length: { minimum: 10 }",
          "+   admin.validates :email, presence: true",
          "+ end",
          "+ with_options if: :is_admin? { |admin| admin.validates :email, presence: true }",
          "- validates :first_name, length: { maximum: 127 }"
        ]
      end

      it 'adds suggestions at the correct line' do
        suggested_line = "\n#{described_class::SUGGEST_MR_COMMENT.chomp}"

        matching_line_numbers = [*2..6, 8, 9, 11]
        matching_line_numbers.each do |line_number|
          expect(model_validations).to receive(:markdown).with(suggested_line, file: filename, line: line_number)
        end

        model_validations.add_comment_for_added_validations
      end
    end

    context 'when model does not have a newly added validation' do
      let(:file_diff) do
        [
          "+ scope :admins, -> { where(admin: true) }",
          "- validates :first_name, length: { maximum: 127 }"
        ]
      end

      it 'does not add suggestion' do
        expect(model_validations).not_to receive(:markdown)

        model_validations.add_comment_for_added_validations
      end
    end
  end

  describe '#changed_model_files' do
    let(:expected_files) do
      %w[
        app/models/user.rb
        app/models/users/user_follow_user.rb
        ee/app/models/ee/user.rb
        ee/app/models/sca/license_policy.rb
        app/models/concerns/presentable.rb
      ]
    end

    before do
      added_files = %w[app/models/user_preferences.rb app/models/concerns/presentable.rb]
      modified_files = %w[
        app/models/user.rb
        app/models/users/user_follow_user.rb
        ee/app/models/ee/user.rb
        ee/app/models/sca/license_policy.rb
        config/metrics/count_7d/new_metric.yml
        app/assets/index.js
      ]

      allow(model_validations.helper).to receive(:added_files).and_return(added_files)
      allow(model_validations.helper).to receive(:modified_files).and_return(modified_files)
    end

    it 'returns added and modified files' do
      expect(model_validations.changed_model_files).to match_array(expected_files)
    end
  end
end
