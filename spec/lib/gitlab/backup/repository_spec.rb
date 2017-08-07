require 'spec_helper'

describe Backup::Repository do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    allow_any_instance_of(described_class).to receive(:progress).and_return(progress)
  end

  describe '#dump' do
    describe 'repo failure' do
      before do
        allow_any_instance_of(Repository).to receive(:empty_repo?).and_raise(Rugged::OdbError)
        allow(Gitlab::Popen).to receive(:popen).and_return(['normal output', 0])
      end

      it 'does not raise error' do
        expect { described_class.new.dump }.not_to raise_error
      end

      it 'shows the appropriate error' do
        described_class.new.dump

        expect(progress).to have_received(:puts).with("Ignoring repository error and continuing backing up project: #{project.full_path} - Rugged::OdbError")
      end
    end

    describe 'command failure' do
      before do
        allow_any_instance_of(Repository).to receive(:empty_repo?).and_return(false)
        allow(Gitlab::Popen).to receive(:popen).and_return(['error', 1])
      end

      it 'shows the appropriate error' do
        described_class.new.dump

        expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} - error")
      end
    end
  end

  describe '#restore' do
    describe 'command failure' do
      before do
        allow(Gitlab::Popen).to receive(:popen).and_return(['error', 1])
      end

      it 'shows the appropriate error' do
        described_class.new.restore

        expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} - error")
      end
    end
  end

  describe '#empty_repo?' do
    context 'for a wiki' do
      let(:wiki) { create(:project_wiki) }

      context 'wiki repo has content' do
        let!(:wiki_page) { create(:wiki_page, wiki: wiki) }

        before do
          wiki.repository.exists? # initial cache
        end

        context '`repository.exists?` is incorrectly cached as false' do
          before do
            repo = wiki.repository
            repo.send(:cache).expire(:exists?)
            repo.send(:cache).fetch(:exists?) { false }
            repo.send(:instance_variable_set, :@exists, false)
          end

          it 'returns false, regardless of bad cache value' do
            expect(described_class.new.send(:empty_repo?, wiki)).to be_falsey
          end
        end

        context '`repository.exists?` is correctly cached as true' do
          it 'returns false' do
            expect(described_class.new.send(:empty_repo?, wiki)).to be_falsey
          end
        end
      end

      context 'wiki repo does not have content' do
        context '`repository.exists?` is incorrectly cached as true' do
          before do
            repo = wiki.repository
            repo.send(:cache).expire(:exists?)
            repo.send(:cache).fetch(:exists?) { true }
            repo.send(:instance_variable_set, :@exists, true)
          end

          it 'returns true, regardless of bad cache value' do
            expect(described_class.new.send(:empty_repo?, wiki)).to be_truthy
          end
        end

        context '`repository.exists?` is correctly cached as false' do
          it 'returns true' do
            expect(described_class.new.send(:empty_repo?, wiki)).to be_truthy
          end
        end
      end
    end
  end
end
