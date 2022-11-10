# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'file template shared examples' do |filename, file_extension|
  describe '.all' do
    it "strips the #{file_extension} suffix" do
      expect(subject.all.first.name).not_to end_with(file_extension)
    end

    it 'ensures that the template name is used exactly once' do
      all = subject.all.group_by(&:name)
      duplicates = all.select { |_, templates| templates.length > 1 }

      expect(duplicates).to be_empty
    end
  end

  describe '.by_category' do
    it 'returns sorted results' do
      result = described_class.by_category('General')

      expect(result).to eq(result.sort)
    end
  end

  describe '.find' do
    it 'returns nil if the file does not exist' do
      expect(subject.find('nonexistent-file')).to be nil
    end

    it 'returns the corresponding object of a valid file' do
      template = subject.find(filename)

      expect(template).to be_a described_class
      expect(template.name).to eq(filename)
    end
  end

  describe '#<=>' do
    it 'sorts lexicographically' do
      one = described_class.new("a.#{file_extension}")
      other = described_class.new("z.#{file_extension}")

      expect(one.<=>(other)).to be(-1)
      expect([other, one].sort).to eq([one, other])
    end
  end
end

RSpec.shared_examples 'acts as branch pipeline' do |jobs|
  context 'when branch pipeline' do
    let(:pipeline_branch) { default_branch }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch) }
    let(:pipeline) { service.execute(:push).payload }

    it 'includes a job' do
      expect(pipeline.builds.pluck(:name)).to match_array(jobs)
    end
  end
end

RSpec.shared_examples 'acts as MR pipeline' do |jobs, files|
  context 'when MR pipeline' do
    let(:pipeline_branch) { 'patch-1' }
    let(:service) { MergeRequests::CreatePipelineService.new(project: project, current_user: user) }
    let(:pipeline) { service.execute(merge_request).payload }

    let(:merge_request) do
      create(:merge_request,
        source_project: project,
        source_branch: pipeline_branch,
        target_project: project,
        target_branch: default_branch)
    end

    before do
      files.each do |filename, contents|
        project.repository.create_file(
          project.creator,
          filename,
          contents,
          message: "Add #{filename}",
          branch_name: pipeline_branch)
      end
    end

    it 'includes a job' do
      expect(pipeline).to be_merge_request_event
      expect(pipeline.builds.pluck(:name)).to match_array(jobs)
    end
  end
end
