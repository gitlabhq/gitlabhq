# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset do
  describe '.paginate' do
    subject { described_class.paginate(request_context, relation) }

    let(:request_context) { double }
    let(:relation) { double }
    let(:pager) { double }
    let(:result) { double }

    it 'uses Pager to paginate the relation' do
      expect(Gitlab::Pagination::Keyset::Pager).to receive(:new).with(request_context).and_return(pager)
      expect(pager).to receive(:paginate).with(relation).and_return(result)

      expect(subject).to eq(result)
    end
  end

  describe '.available?' do
    subject { described_class }

    let(:request_context) { double("request context", page: page)}
    let(:page) { double("page", order_by: order_by) }

    shared_examples_for 'keyset pagination is available' do
      it 'returns true for Project' do
        expect(subject.available?(request_context, Project.all)).to be_truthy
      end

      it 'return false for other types of relations' do
        expect(subject.available?(request_context, User.all)).to be_falsey
      end
    end

    context 'with order-by id asc' do
      let(:order_by) { { id: :asc } }

      it_behaves_like 'keyset pagination is available'
    end

    context 'with order-by id desc' do
      let(:order_by) { { id: :desc } }

      it_behaves_like 'keyset pagination is available'
    end

    context 'with other order-by columns' do
      let(:order_by) { { created_at: :desc, id: :desc } }

      it 'returns false for Project' do
        expect(subject.available?(request_context, Project.all)).to be_falsey
      end

      it 'return false for other types of relations' do
        expect(subject.available?(request_context, User.all)).to be_falsey
      end
    end
  end
end
