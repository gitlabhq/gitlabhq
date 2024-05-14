# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::CursorBasedKeyset do
  subject { described_class }

  describe '.available_for_type?' do
    it 'returns true for when class implements .supported_keyset_orderings' do
      model = Class.new(ApplicationRecord) do
        self.table_name = 'users'

        def self.supported_keyset_orderings
          { id: [:desc] }
        end
      end

      expect(subject.available_for_type?(model.all)).to eq(true)
    end

    it 'return false when class does not implement .supported_keyset_orderings' do
      model = Class.new(ApplicationRecord) do
        self.table_name = 'users'
      end

      expect(subject.available_for_type?(model.all)).to eq(false)
    end
  end

  describe '.enforced_for_type?' do
    let_it_be(:project) { create(:project) }

    subject { described_class.enforced_for_type?(project, relation) }

    where(:relation, :result) do
      [
        [Group.all, true],
        [User.all, true],
        [AuditEvent.all, false]
      ]
    end

    with_them do
      it "returns true only for enforced types" do
        expect(subject).to be result
      end
    end

    context 'when relation is Ci::Build' do
      let(:relation) { Ci::Build.all }

      before do
        stub_feature_flags(enforce_ci_builds_pagination_limit: false)
      end

      context 'when feature flag enforce_ci_builds_pagination_limit is enabled' do
        before do
          stub_feature_flags(enforce_ci_builds_pagination_limit: project)
        end

        it { is_expected.to be true }
      end

      context 'when feature fllag enforce_ci_builds_pagination_limit is disabled' do
        it { is_expected.to be false }
      end
    end
  end

  describe '.available?' do
    let(:request_context) { double('request_context', params: { order_by: order_by, sort: sort }) }
    let(:cursor_based_request_context) { Gitlab::Pagination::Keyset::CursorBasedRequestContext.new(request_context) }
    let(:model) do
      Class.new(ApplicationRecord) do
        self.table_name = 'users'

        def self.supported_keyset_orderings
          { id: [:desc] }
        end
      end
    end

    context 'when param order is supported by the model' do
      let(:order_by) { :id }
      let(:sort) { :desc }

      it 'returns true' do
        expect(subject.available?(cursor_based_request_context, model.all)).to eq(true)
      end
    end

    context 'when sort param is not supported by the model' do
      let(:order_by) { :id }
      let(:sort) { :asc }

      it 'returns false' do
        expect(subject.available?(cursor_based_request_context, model.all)).to eq(false)
      end
    end

    context 'when order_by params is not supported by the model' do
      let(:order_by) { :name }
      let(:sort) { :desc }

      it 'returns false' do
        expect(subject.available?(cursor_based_request_context, model.all)).to eq(false)
      end
    end

    context 'when model does not implement .supported_keyset_orderings' do
      let(:order_by) { :id }
      let(:sort) { :desc }
      let(:model) do
        Class.new(ApplicationRecord) do
          self.table_name = 'users'
        end
      end

      it 'returns false' do
        expect(subject.available?(cursor_based_request_context, model.all)).to eq(false)
      end
    end
  end
end
