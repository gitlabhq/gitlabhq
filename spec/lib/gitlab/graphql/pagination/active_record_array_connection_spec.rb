# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::ActiveRecordArrayConnection do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:items) { create_list(:package_build_info, 3) }

  let_it_be(:context) do
    GraphQL::Query::Context.new(
      query: GraphQL::Query.new(GitlabSchema, document: nil, context: {}, variables: {}),
      values: {}
    )
  end

  let(:first) { nil }
  let(:last) { nil }
  let(:after) { nil }
  let(:before) { nil }
  let(:max_page_size) { nil }

  let(:connection) do
    described_class.new(
      items,
      context: context,
      first: first,
      last: last,
      after: after,
      before: before,
      max_page_size: max_page_size
    )
  end

  it_behaves_like 'a connection with collection methods'

  it_behaves_like 'a redactable connection' do
    let(:unwanted) { items[1] }
  end

  describe '#nodes' do
    subject { connection.nodes }

    it { is_expected.to match_array(items) }

    context 'with first set' do
      let(:first) { 2 }

      it { is_expected.to match_array([items[0], items[1]]) }
    end

    context 'with last set' do
      let(:last) { 2 }

      it { is_expected.to match_array([items[1], items[2]]) }
    end
  end

  describe '#next_page?' do
    subject { connection.next_page? }

    where(:before, :first, :max_page_size, :result) do
      nil | nil | nil | false
      1   | nil | nil | true
      nil | 1   | nil | true
      nil | 10  | nil | false
      nil | 1   | 1   | true
      nil | 1   | 10  | true
      nil | 10  | 10  | false
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#previous_page?' do
    subject { connection.previous_page? }

    where(:after, :last, :max_page_size, :result) do
      nil | nil | nil | false
      1   | nil | nil | true
      nil | 1   | nil | true
      nil | 10  | nil | false
      nil | 1   | 1   | true
      nil | 1   | 10  | true
      nil | 10  | 10  | false
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#cursor_for' do
    let(:item) { items[0] }
    let(:expected_result) do
      GitlabSchema.cursor_encoder.encode(
        Gitlab::Json.dump(id: item.id.to_s),
        nonce: true
      )
    end

    subject { connection.cursor_for(item) }

    it { is_expected.to eq(expected_result) }

    context 'with a BatchLoader::GraphQL item' do
      let_it_be(:user) { create(:user) }

      let(:item) { ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::User, user.id).find }
      let(:expected_result) do
        GitlabSchema.cursor_encoder.encode(
          Gitlab::Json.dump(id: user.id.to_s),
          nonce: true
        )
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#dup' do
    subject { connection.dup }

    it 'properly handles items duplication' do
      connection2 = subject

      connection2 << create(:package_build_info)

      expect(connection.items).not_to eq(connection2.items)
    end
  end
end
