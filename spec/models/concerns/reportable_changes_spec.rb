# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReportableChanges, feature_category: :code_review_workflow do
  let_it_be(:base_klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Dirty

      # Stub ActiveRecord::Persistence behavior
      def save!
        # noop
        changes_applied
        true
      end

      # Stub both ActiveModel::Dirty and ActiveRecord::Persistence behavior
      def reload
        # noop
        clear_changes_information
        self
      end
    end
  end

  let_it_be(:klass) do
    Class.new(base_klass) do
      include ReportableChanges

      attr_accessor :name

      define_attribute_methods :name

      def self.model_name
        ActiveModel::Name.new(self, nil, 'User')
      end

      # Stub ActiveModel::Dirty behavior
      def name=(val)
        name_will_change! unless val == @name
        @name = val
      end
    end
  end

  describe '#reportable_changes' do
    subject { user.reportable_changes }

    let(:initial_name) { "bob" }
    let(:intermediate_name) { "robert" }
    let(:final_name) { "rob" }

    context "when the object is newly created" do
      let(:user) { klass.new(name: initial_name).tap(&:save!) }

      it { is_expected.to eq(user.previous_changes) }
    end

    context "when the object is loaded from persistence" do
      let(:user) { klass.new(name: initial_name).tap(&:save!).reload }

      context "and multiple saves occur" do
        before do
          user.name = intermediate_name
          user.save!
          user.name = final_name
          user.save!
        end

        it { is_expected.to include(name: [initial_name, final_name]) }
      end
    end
  end
end
