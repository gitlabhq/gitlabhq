require 'spec_helper'

describe Backup::Repository, lib: true do
  include StubENV

  let(:progress) { StringIO.new }
  let!(:project) { create(:empty_project) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    @old_progress = $progress # rubocop:disable Style/GlobalVars
    $progress = progress # rubocop:disable Style/GlobalVars
  end

  after do
    $progress = @old_progress # rubocop:disable Style/GlobalVars
  end

  describe 'repo failure' do
    before do
      allow_any_instance_of(Project).to receive(:empty_repo?).and_raise(Rugged::OdbError)
      allow(Gitlab::Popen).to receive(:popen).and_return(['normal output', 0])
    end

    it 'does not raise error' do
      expect { described_class.new.dump }.not_to raise_error
    end
  end
end
