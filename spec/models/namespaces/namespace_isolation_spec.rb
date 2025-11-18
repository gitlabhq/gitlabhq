# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::NamespaceIsolation, feature_category: :organization do
  let(:factory_name) { :namespace_isolation }

  it_behaves_like 'an IsolationRecord model'

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).inverse_of(:isolated_record) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
  end

  describe 'database constraints' do
    let_it_be(:namespace) { create(:namespace) }

    it 'enforces unique namespace_id' do
      create(:namespace_isolation, namespace: namespace)

      expect do
        create(:namespace_isolation, namespace: namespace)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'enforces not null constraint on namespace_id' do
      expect do
        described_class.new(namespace_id: nil, isolated: false).save!(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'enforces not null constraint on isolated' do
      expect do
        described_class.new(namespace: namespace, isolated: nil).save!(validate: false)
      end.to raise_error(ActiveRecord::NotNullViolation)
    end
  end
end
