# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Loggable, feature_category: :importers do
  subject(:log_base_data) { loggable_class.new(project).send(:log_base_data) }

  let_it_be(:project) { create(:project) }

  let(:loggable_class) do
    Class.new do
      include Gitlab::BitbucketImport::Loggable

      attr_reader :project

      def self.name
        'BitbucketImportLoggable'
      end

      def initialize(project)
        @project = project
      end
    end
  end

  it 'includes the project organization id' do
    expect(log_base_data).to include(
      Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id
    )
  end
end
