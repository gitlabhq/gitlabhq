# frozen_string_literal: true

RSpec.shared_examples 'Wikis::CreateAttachmentService#execute' do |container_type|
  let(:container) { create(container_type, :wiki_repo) }
  let(:wiki) { container.wiki }

  let(:user) { create(:user) }
  let(:file_name) { 'filename.txt' }
  let(:file_path_regex) { %r{#{described_class::ATTACHMENT_PATH}/\h{32}/#{file_name}} }

  let(:file_opts) do
    {
      file_name: file_name,
      file_content: 'Content of attachment'
    }
  end

  let(:opts) { file_opts }

  let(:service) { Wikis::CreateAttachmentService.new(container: container, current_user: user, params: opts) }

  subject(:service_execute) { service.execute[:result] }

  before do
    container.add_developer(user)
  end

  context 'creates wiki repository if it does not exist' do
    let(:container) { create(container_type) } # rubocop:disable Rails/SaveBang

    it 'creates wiki repository' do
      expect { service.execute }.to change { container.wiki.repository.exists? }.to(true)
    end

    context 'if an error is raised creating the repository' do
      it 'catches error and return gracefully' do
        allow(container.wiki).to receive(:repository_exists?).and_return(false)

        result = service.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'Error creating the wiki repository'
      end
    end
  end

  context 'creates branch if it does not exists' do
    let(:branch_name) { 'new_branch' }
    let(:opts) { file_opts.merge(branch_name: branch_name) }

    it do
      expect(wiki.repository.branches).to be_empty
      expect { service.execute }.to change { wiki.repository.branches.count }.by(1)
      expect(wiki.repository.branches.first.name).to eq branch_name
    end
  end

  it 'adds file to the repository' do
    expect(wiki.repository.ls_files('HEAD')).to be_empty

    service.execute

    files = wiki.repository.ls_files('HEAD')
    expect(files.count).to eq 1
    expect(files.first).to match(file_path_regex)
  end

  context 'returns' do
    before do
      allow(SecureRandom).to receive(:hex).and_return('fixed_hex')

      service_execute
    end

    it 'returns related information', :aggregate_failures do
      expect(service_execute[:file_name]).to eq file_name
      expect(service_execute[:file_path]).to eq 'uploads/fixed_hex/filename.txt'
      expect(service_execute[:branch]).to eq wiki.default_branch
      expect(service_execute[:commit]).not_to be_empty
    end
  end
end
