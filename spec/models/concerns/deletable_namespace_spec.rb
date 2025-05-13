# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeletableNamespace, feature_category: :groups_and_projects do
  let(:model) do
    Class.new do
      include DeletableNamespace
    end
  end

  let(:record) { model.new }

  describe '#self_deletion_in_progress?' do
    it 'raises NotImplementedError by default' do
      expect { record.self_deletion_in_progress? }.to raise_error(NotImplementedError)
    end

    context 'when implemented' do
      before do
        model.send(:define_method, :self_deletion_in_progress?) do
          true
        end
      end

      it 'returns the implemented value' do
        expect(record.self_deletion_in_progress?).to be_truthy
      end
    end
  end

  describe '#deletion_in_progress_or_scheduled_in_hierarchy_chain?' do
    context 'when #self_deletion_in_progress? is false' do
      before do
        allow(record).to receive(:self_deletion_in_progress?).and_return(false)
      end

      it 'returns false' do
        expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_falsy
      end

      context 'when #scheduled_for_deletion_in_hierarchy_chain? is true' do
        before do
          allow(record).to receive(:scheduled_for_deletion_in_hierarchy_chain?).and_return(true)
        end

        it 'returns true' do
          expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_truthy
        end
      end
    end

    context 'when #self_deletion_in_progress? is true' do
      before do
        allow(record).to receive(:self_deletion_in_progress?).and_return(true)
      end

      it 'returns true' do
        expect(record.deletion_in_progress_or_scheduled_in_hierarchy_chain?).to be_truthy
      end
    end
  end
end
