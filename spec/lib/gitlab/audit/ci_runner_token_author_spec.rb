# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::CiRunnerTokenAuthor do
  describe '#initialize' do
    it 'sets correct attributes' do
      expect(described_class.new(token: 'abc1234567', entity_type: 'Project', entity_path: 'd/e'))
        .to have_attributes(id: -1, name: 'Registration token: abc1234567')
    end
  end

  describe '#full_path' do
    subject { author.full_path }

    context 'with instance registration token' do
      let(:author) { described_class.new(token: 'abc1234567', entity_type: 'User', entity_path: nil) }

      it 'returns correct url' do
        is_expected.to eq('/admin/runners')
      end
    end

    context 'with group registration token' do
      let(:author) { described_class.new(token: 'abc1234567', entity_type: 'Group', entity_path: 'a/b') }

      it 'returns correct url' do
        expect(::Gitlab::Routing.url_helpers).to receive(:group_settings_ci_cd_path)
          .once
          .with('a/b', { anchor: 'js-runners-settings' })
          .and_return('/path/to/group/runners')

        is_expected.to eq('/path/to/group/runners')
      end
    end

    context 'with project registration token' do
      let(:author) { described_class.new(token: 'abc1234567', entity_type: 'Project', entity_path: project.full_path) }
      let(:project) { create(:project) }

      it 'returns correct url' do
        expect(::Gitlab::Routing.url_helpers).to receive(:project_settings_ci_cd_path)
          .once
          .with(project, { anchor: 'js-runners-settings' })
          .and_return('/path/to/project/runners')

        is_expected.to eq('/path/to/project/runners')
      end
    end
  end
end
