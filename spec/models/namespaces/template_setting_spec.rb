# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::TemplateSetting, feature_category: :code_suggestions do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:file_template_project).class_name('Project').optional }
    it { is_expected.to belong_to(:duo_template_project).class_name('Project').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
  end
end
