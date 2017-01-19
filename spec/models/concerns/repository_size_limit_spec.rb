require 'spec_helper'

describe RepositorySizeLimit do
  context Project do
    context 'callback' do
      describe '#convert_from_megabyte_to_byte' do
        let(:project) { build(:empty_project, repository_size_limit: 10) }

        before do
          project.update!(repository_size_limit: repository_size_limit)
          project.reload
        end

        context 'when repository_size_limit is present and have changed' do
          let(:repository_size_limit) { 20 }

          it { expect(project.repository_size_limit).to eql(20 * 1.megabyte) }
        end

        context 'when repository_size_limit is present but have not changed' do
          let(:repository_size_limit) { 10 }

          it { expect(project.repository_size_limit).to eql(10 * 1.megabyte) }
        end

        context 'when repository_size_limit is not present' do
          let(:repository_size_limit) { nil }

          it { expect(project.repository_size_limit).to be_nil }
        end
      end
    end
  end

  context Group do
    context 'callback' do
      describe '#convert_from_megabyte_to_byte' do
        let(:group) { build(:group, repository_size_limit: 10) }

        before do
          group.update!(repository_size_limit: repository_size_limit)
          group.reload
        end

        context 'when repository_size_limit is present and have changed' do
          let(:repository_size_limit) { 20 }

          it { expect(group.repository_size_limit).to eql(20 * 1.megabyte) }
        end

        context 'when repository_size_limit is present but have not changed' do
          let(:repository_size_limit) { 10 }

          it { expect(group.repository_size_limit).to eql(10 * 1.megabyte) }
        end

        context 'when repository_size_limit is not present' do
          let(:repository_size_limit) { nil }

          it { expect(group.repository_size_limit).to be_nil }
        end
      end
    end
  end

  context ApplicationSetting do
    context 'callback' do
      describe '#convert_from_megabyte_to_byte' do
        let(:setting) { ApplicationSetting.create_from_defaults }

        before do
          setting.update!(repository_size_limit: 10)
          setting.update!(repository_size_limit: repository_size_limit)
          setting.reload
        end

        context 'when repository_size_limit is present and have changed' do
          let(:repository_size_limit) { 20 }

          it { expect(setting.repository_size_limit).to eql(20 * 1.megabyte) }
        end

        context 'when repository_size_limit is present but have not changed' do
          let(:repository_size_limit) { 10 }

          it { expect(setting.repository_size_limit).to eql(10 * 1.megabyte) }
        end
      end
    end
  end
end
