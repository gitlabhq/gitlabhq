# frozen_string_literal: true

require 'spec_helper'

describe Projects::UpdatePagesConfigurationService do
  let(:project) { create(:project) }
  let(:service) { described_class.new(project) }

  describe "#update" do
    let(:file) { Tempfile.new('pages-test') }

    subject { service.execute }

    after do
      file.close
      file.unlink
    end

    before do
      allow(service).to receive(:pages_config_file).and_return(file.path)
    end

    context 'when configuration changes' do
      it 'updates the .update file' do
        expect(service).to receive(:reload_daemon).and_call_original

        expect(subject).to include(status: :success, reload: true)
      end
    end

    context 'when configuration does not change' do
      before do
        # we set the configuration
        service.execute
      end

      it 'does not update the .update file' do
        expect(service).not_to receive(:reload_daemon)

        expect(subject).to include(status: :success, reload: false)
      end
    end
  end
end
