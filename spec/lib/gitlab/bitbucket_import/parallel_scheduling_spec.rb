# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::ParallelScheduling, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started, import_source: 'foo/bar',
      import_data_attributes: {
        data: {
          'project_key' => 'key',
          'repo_slug' => 'slug'
        },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let(:importer_class) do
    Class.new do
      include Gitlab::BitbucketImport::ParallelScheduling

      def collection_method
        :issues
      end
    end
  end

  describe '#calculate_job_delay' do
    let(:importer) { importer_class.new(project) }

    before do
      stub_application_setting(concurrent_bitbucket_import_jobs_limit: 2)
    end

    it 'returns an incremental delay', :freeze_time do
      expect(importer.send(:calculate_job_delay, 1)).to eq(0.5.minutes + 1.second)
      expect(importer.send(:calculate_job_delay, 100)).to eq(50.minutes + 1.second)
    end

    it 'deducts the runtime from the delay', :freeze_time do
      allow(importer).to receive(:job_started_at).and_return(1.second.ago)

      expect(importer.send(:calculate_job_delay, 1)).to eq(0.5.minutes)
      expect(importer.send(:calculate_job_delay, 100)).to eq(50.minutes)
    end
  end

  describe '#each_object_to_import' do
    let_it_be(:opened_issue) { Bitbucket::Representation::Issue.new({ 'id' => 1, 'state' => 'OPENED' }) }
    let_it_be(:object) { opened_issue.to_hash }

    let(:importer) { importer_class.new(project) }

    context 'without representation_type' do
      it 'raises NotImplementedError' do
        expect { importer_class.new(project).each_object_to_import }.to raise_error(NotImplementedError)
      end
    end

    context 'with representation_type' do
      before do
        allow(importer)
          .to receive(:representation_type)
          .and_return(:issue)
      end

      it 'yields every object to import' do
        page = instance_double('Bitbucket::Page', attrs: [], items: [opened_issue])
        allow(page).to receive(:next?).and_return(true)
        allow(page).to receive(:next).and_return('https://example.com/next')

        allow_next_instance_of(Bitbucket::Client) do |client|
          expect(client)
            .to receive(:each_page)
            .with(:issues, :issue, 'foo/bar', { next_url: nil })
            .and_yield(page)
        end

        expect(importer.page_keyset)
          .to receive(:set)
          .with('https://example.com/next')
          .and_return(true)

        expect(importer)
          .to receive(:already_enqueued?)
          .with(object)
          .and_return(false)

        expect(importer)
          .to receive(:mark_as_enqueued)
          .with(object)

        expect { |b| importer.each_object_to_import(&b) }
          .to yield_with_args(object)
      end

      it 'resumes from the last page' do
        page = instance_double('Bitbucket::Page', attrs: [], items: [opened_issue])
        allow(page).to receive(:next?).and_return(true)
        allow(page).to receive(:next).and_return('https://example.com/next2')

        expect(importer.page_keyset)
          .to receive(:current)
          .and_return('https://example.com/next')

        allow_next_instance_of(Bitbucket::Client) do |client|
          expect(client)
            .to receive(:each_page)
            .with(:issues, :issue, 'foo/bar', {
              next_url: 'https://example.com/next'
            })
            .and_yield(page)
        end

        expect(importer.page_keyset)
          .to receive(:set)
          .with('https://example.com/next2')
          .and_return(true)

        expect(importer)
          .to receive(:already_enqueued?)
          .with(object)
          .and_return(false)

        expect(importer)
          .to receive(:mark_as_enqueued)
          .with(object)

        expect { |b| importer.each_object_to_import(&b) }
          .to yield_with_args(object)
      end

      it 'does not yield the object if it was already imported' do
        page = instance_double('Bitbucket::Page', attrs: [], items: [opened_issue])
        allow(page).to receive(:next?).and_return(true)
        allow(page).to receive(:next).and_return('https://example.com/next')

        allow_next_instance_of(Bitbucket::Client) do |client|
          expect(client)
            .to receive(:each_page)
            .with(:issues, :issue, 'foo/bar', { next_url: nil })
            .and_yield(page)
        end

        expect(importer.page_keyset)
          .to receive(:set)
          .with('https://example.com/next')
          .and_return(true)

        expect(importer)
          .to receive(:already_enqueued?)
          .with(object)
          .and_return(true)

        expect(importer)
          .not_to receive(:mark_as_enqueued)

        expect { |b| importer.each_object_to_import(&b) }
          .not_to yield_control
      end
    end
  end
end
