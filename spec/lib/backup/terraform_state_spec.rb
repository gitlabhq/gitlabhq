# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::TerraformState do
  let(:progress) { StringIO.new }

  subject(:backup) { described_class.new(progress) }

  describe '#dump' do
    before do
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with('/var/terraform_state').and_return('/var/terraform_state')
      allow(File).to receive(:realpath).with('/var/terraform_state/..').and_return('/var')
      allow(Settings.terraform_state).to receive(:storage_path).and_return('/var/terraform_state')
    end

    it 'uses the correct storage dir in tar command and excludes tmp', :aggregate_failures do
      expect(backup.app_files_dir).to eq('/var/terraform_state')
      expect(backup).to receive(:tar).and_return('blabla-tar')
      expect(backup).to receive(:run_pipeline!).with([%w(blabla-tar --exclude=lost+found --exclude=./tmp -C /var/terraform_state -cf - .), 'gzip -c -1'], any_args).and_return([[true, true], ''])
      expect(backup).to receive(:pipeline_succeeded?).and_return(true)

      backup.dump
    end
  end
end
