# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::States::DestroyService, feature_category: :infrastructure_as_code do
  let_it_be(:state) { create(:terraform_state, :with_version, :deletion_in_progress) }

  let(:file) { instance_double(Terraform::StateUploader, relative_path: 'path') }

  before do
    allow_next_found_instance_of(Terraform::StateVersion) do |version|
      allow(version).to receive(:file).and_return(file)
    end
  end

  describe '#execute' do
    subject { described_class.new(state).execute }

    it 'removes version files from object storage, followed by the state record' do
      expect(file).to receive(:remove!).once
      expect(state).to receive(:destroy!)

      subject
    end

    context 'state is not marked for deletion' do
      let(:state) { create(:terraform_state) }

      it 'does not delete the state' do
        expect(state).not_to receive(:destroy!)

        subject
      end
    end
  end
end
