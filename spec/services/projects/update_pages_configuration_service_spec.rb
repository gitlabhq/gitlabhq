# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdatePagesConfigurationService do
  let(:service) { described_class.new(project) }

  describe "#execute" do
    subject { service.execute }

    context 'when pages are deployed' do
      let_it_be(:project) do
        create(:project).tap(&:mark_pages_as_deployed)
      end

      let(:file) { Tempfile.new('pages-test') }

      before do
        allow(service).to receive(:pages_config_file).and_return(file.path)
      end

      after do
        file.close
        file.unlink
      end

      context 'when configuration changes' do
        it 'updates the config and reloads the daemon' do
          allow(service).to receive(:update_file).and_call_original

          expect(service).to receive(:update_file).with(file.path, an_instance_of(String))
            .and_call_original
          expect(service).to receive(:reload_daemon).and_call_original

          expect(subject).to include(status: :success)
        end
      end

      context 'when configuration does not change' do
        before do
          # we set the configuration
          service.execute
        end

        it 'does not update the .update file' do
          expect(service).not_to receive(:reload_daemon)

          expect(subject).to include(status: :success)
        end
      end
    end

    context 'when pages are not deployed' do
      let_it_be(:project) do
        create(:project).tap(&:mark_pages_as_not_deployed)
      end

      it 'returns successfully' do
        expect(subject).to eq(status: :success)
      end

      it 'does not update the config' do
        expect(service).not_to receive(:update_file)

        subject
      end
    end
  end
end
