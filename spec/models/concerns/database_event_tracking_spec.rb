# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DatabaseEventTracking, :snowplow do
  before do
    allow(Gitlab::Tracking).to receive(:database_event).and_call_original
  end

  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      include DatabaseEventTracking

      self.table_name = 'application_setting_terms'

      self::SNOWPLOW_ATTRIBUTES = %w[id].freeze # rubocop:disable RSpec/LeakyConstantDeclaration
    end
  end

  subject(:create_test_class_record) { test_class.create!(id: 1, terms: "") }

  context 'if event emmiter failed' do
    before do
      allow(Gitlab::Tracking).to receive(:database_event).and_raise(StandardError) # rubocop:disable RSpec/ExpectGitlabTracking
    end

    it 'tracks the exception' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      create_test_class_record
    end
  end

  context 'if product_intelligence_database_event_tracking FF is off' do
    before do
      stub_feature_flags(product_intelligence_database_event_tracking: false)
    end

    it 'does not track the event' do
      create_test_class_record

      expect_no_snowplow_event(tracking_method: :database_event)
    end
  end

  describe 'event tracking' do
    let(:category) { test_class.to_s }
    let(:event) { 'database_event' }

    it 'when created' do
      create_test_class_record

      expect_snowplow_event(
        tracking_method: :database_event,
        category: category,
        action: "#{event}_create",
        label: 'application_setting_terms',
        property: 'create',
        namespace: nil,
        project: nil,
        "id" => 1
      )
    end

    it 'when updated' do
      create_test_class_record
      test_class.first.update!(id: 3)

      expect_snowplow_event(
        tracking_method: :database_event,
        category: category,
        action: "#{event}_update",
        label: 'application_setting_terms',
        property: 'update',
        namespace: nil,
        project: nil,
        "id" => 3
      )
    end

    it 'when destroyed' do
      create_test_class_record
      test_class.first.destroy!

      expect_snowplow_event(
        tracking_method: :database_event,
        category: category,
        action: "#{event}_destroy",
        label: 'application_setting_terms',
        property: 'destroy',
        namespace: nil,
        project: nil,
        "id" => 1
      )
    end
  end
end
