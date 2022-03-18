# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'backup object' do |setting|
  let(:progress) { StringIO.new }
  let(:backup_path) { "/var/#{setting}" }

  subject(:backup) { described_class.new(progress) }

  describe '#dump' do
    before do
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with(backup_path).and_return(backup_path)
      allow(File).to receive(:realpath).with("#{backup_path}/..").and_return('/var')
      allow(Settings.send(setting)).to receive(:storage_path).and_return(backup_path)
    end

    it 'uses the correct storage dir in tar command and excludes tmp', :aggregate_failures do
      expect(backup).to receive(:tar).and_return('blabla-tar')
      expect(backup).to receive(:run_pipeline!).with([%W(blabla-tar --exclude=lost+found --exclude=./tmp -C #{backup_path} -cf - .), 'gzip -c -1'], any_args).and_return([[true, true], ''])
      expect(backup).to receive(:pipeline_succeeded?).and_return(true)

      backup.dump('backup_object.tar.gz')
    end
  end
end

RSpec.describe Backup::Packages do
  it_behaves_like 'backup object', 'packages'
end

RSpec.describe Backup::TerraformState do
  it_behaves_like 'backup object', 'terraform_state'
end
