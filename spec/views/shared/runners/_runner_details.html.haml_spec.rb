# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/runners/_runner_details.html.haml' do
  include PageLayoutHelper

  let(:runner) do
    create(:ci_runner, name: 'test runner',
                       version: '11.4.0',
                       ip_address: '127.1.2.3',
                       revision: 'abcd1234',
                       architecture: 'amd64' )
  end

  before do
    allow(view).to receive(:runner) { runner }
  end

  subject do
    render
    rendered
  end

  describe 'Page title' do
    before do
      expect(view).to receive(:page_title).with("##{runner.id} (#{runner.short_sha})")
    end

    it 'sets proper page title' do
      render
    end
  end

  describe 'Runner id and type' do
    context 'when runner is of type instance' do
      it { is_expected.to have_content("Runner ##{runner.id} shared") }
    end

    context 'when runner is of type group' do
      let(:runner) { create(:ci_runner, :group) }

      it { is_expected.to have_content("Runner ##{runner.id} group") }
    end

    context 'when runner is of type project' do
      let(:runner) { create(:ci_runner, :project) }

      it { is_expected.to have_content("Runner ##{runner.id} specific") }
    end
  end

  describe 'Active value' do
    context 'when runner is active' do
      it { is_expected.to have_content('Active Yes') }
    end

    context 'when runner is inactive' do
      let(:runner) { create(:ci_runner, :inactive) }

      it { is_expected.to have_content('Active No') }
    end
  end

  describe 'Protected value' do
    context 'when runner is not protected' do
      it { is_expected.to have_content('Protected No') }
    end

    context 'when runner is protected' do
      let(:runner) { create(:ci_runner, :ref_protected) }

      it { is_expected.to have_content('Protected Yes') }
    end
  end

  describe 'Can run untagged jobs value' do
    context 'when runner run untagged job is set' do
      it { is_expected.to have_content('Can run untagged jobs Yes') }
    end

    context 'when runner run untagged job is unset' do
      let(:runner) { create(:ci_runner, :tagged_only) }

      it { is_expected.to have_content('Can run untagged jobs No') }
    end
  end

  describe 'Locked to this project value' do
    context 'when runner locked is not set' do
      it { is_expected.to have_content('Locked to this project No') }

      context 'when runner is of type group' do
        let(:runner) { create(:ci_runner, :group) }

        it { is_expected.not_to have_content('Locked to this project') }
      end
    end

    context 'when runner locked is set' do
      let(:runner) { create(:ci_runner, :locked) }

      it { is_expected.to have_content('Locked to this project Yes') }

      context 'when runner is of type group' do
        let(:runner) { create(:ci_runner, :group, :locked) }

        it { is_expected.not_to have_content('Locked to this project') }
      end
    end
  end

  describe 'Tags value' do
    context 'when runner does not have tags' do
      it { is_expected.to have_content('Tags') }
      it { is_expected.not_to have_selector('span.badge.badge-primary')}
    end

    context 'when runner have tags' do
      let(:runner) { create(:ci_runner, tag_list: %w(tag2 tag3 tag1)) }

      it { is_expected.to have_content('Tags tag1 tag2 tag3') }
      it { is_expected.to have_selector('span.badge.badge-primary')}
    end
  end

  describe 'Metadata values' do
    it { is_expected.to have_content("Name #{runner.name}") }
    it { is_expected.to have_content("Version #{runner.version}") }
    it { is_expected.to have_content("IP Address #{runner.ip_address}") }
    it { is_expected.to have_content("Revision #{runner.revision}") }
    it { is_expected.to have_content("Platform #{runner.platform}") }
    it { is_expected.to have_content("Architecture #{runner.architecture}") }
    it { is_expected.to have_content("Description #{runner.description}") }
  end

  describe 'Maximum job timeout value' do
    let(:runner) { create(:ci_runner, maximum_timeout: 5400) }

    it { is_expected.to have_content('Maximum job timeout 1h 30m') }
  end

  describe 'Last contact value' do
    context 'when runner have not contacted yet' do
      it { is_expected.to have_content('Last contact Never') }
    end

    context 'when runner have already contacted' do
      let(:runner) { create(:ci_runner, contacted_at: DateTime.now - 6.days) }
      let(:expected_contacted_at) { I18n.l(runner.contacted_at, format: "%b %d, %Y") }

      it { is_expected.to have_content("Last contact #{expected_contacted_at}") }
    end
  end
end
