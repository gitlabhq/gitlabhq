# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset do
  describe '.available_for_type?' do
    subject { described_class }

    it 'returns true for Project' do
      expect(subject.available_for_type?(Project.all)).to be_truthy
    end

    it 'return false for other types of relations' do
      expect(subject.available_for_type?(User.all)).to be_falsey
    end
  end

  describe '.available?' do
    subject { described_class }

    let(:request_context) { double("request context", page: page) }
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
