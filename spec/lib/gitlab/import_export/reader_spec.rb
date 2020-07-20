# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Reader do
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }

  describe '#project_tree' do
    subject { described_class.new(shared: shared).project_tree }

    it 'delegates to AttributesFinder#find_root' do
      expect_next_instance_of(Gitlab::ImportExport::AttributesFinder) do |instance|
        expect(instance).to receive(:find_root).with(:project)
      end

      subject
    end

    context 'when exception raised' do
      before do
        expect_next_instance_of(Gitlab::ImportExport::AttributesFinder) do |instance|
          expect(instance).to receive(:find_root).with(:project).and_raise(StandardError)
        end
      end

      it { is_expected.to be false }

      it 'logs the error' do
        expect(shared).to receive(:error).with(instance_of(StandardError))

        subject
      end
    end
  end

  describe '#group_members_tree' do
    subject { described_class.new(shared: shared).group_members_tree }

    it 'delegates to AttributesFinder#find_root' do
      expect_next_instance_of(Gitlab::ImportExport::AttributesFinder) do |instance|
        expect(instance).to receive(:find_root).with(:group_members)
      end

      subject
    end
  end
end
