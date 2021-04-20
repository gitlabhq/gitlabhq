# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActiveRecord locking' do
  let(:issue) { create(:issue) }

  shared_examples 'locked model' do
    before do
      issue.update_column(:lock_version, start_lock_version)
    end

    it 'can be updated' do
      issue.update!(title: "New title")

      expect(issue.reload.lock_version).to eq(new_lock_version)
    end

    it 'can be deleted' do
      expect { issue.destroy! }.to change { Issue.count }.by(-1)
    end
  end

  context 'when lock_version is NULL' do
    let(:start_lock_version) { nil }
    let(:new_lock_version) { 1 }

    it_behaves_like 'locked model'
  end

  context 'when lock_version is 0' do
    let(:start_lock_version) { 0 }
    let(:new_lock_version) { 1 }

    it_behaves_like 'locked model'
  end

  context 'when lock_version is 1' do
    let(:start_lock_version) { 1 }
    let(:new_lock_version) { 2 }

    it_behaves_like 'locked model'
  end
end
