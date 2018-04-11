require 'spec_helper'

describe Gitlab::Wiki::CommitterWithHooks, seed_helper: true do
  shared_examples 'calling wiki hooks' do
    let(:project) { create(:project) }
    let(:user) { project.owner }
    let(:project_wiki) { ProjectWiki.new(project, user) }
    let(:wiki) { project_wiki.wiki }
    let(:options) do
      {
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
        message: 'commit message'
      }
    end

    subject { described_class.new(wiki, options) }

    before do
      project_wiki.create_page('home', 'test content')
    end

    shared_examples 'failing pre-receive hook' do
      before do
        expect_any_instance_of(Gitlab::Git::HooksService).to receive(:run_hook).with('pre-receive').and_return([false, ''])
        expect_any_instance_of(Gitlab::Git::HooksService).not_to receive(:run_hook).with('update')
        expect_any_instance_of(Gitlab::Git::HooksService).not_to receive(:run_hook).with('post-receive')
      end

      it 'raises exception' do
        expect { subject.commit }.to raise_error(Gitlab::Git::Wiki::OperationError)
      end

      it 'does not create a new commit inside the repository' do
        current_rev = find_current_rev

        expect { subject.commit }.to raise_error(Gitlab::Git::Wiki::OperationError)

        expect(current_rev).to eq find_current_rev
      end
    end

    shared_examples 'failing update hook' do
      before do
        expect_any_instance_of(Gitlab::Git::HooksService).to receive(:run_hook).with('pre-receive').and_return([true, ''])
        expect_any_instance_of(Gitlab::Git::HooksService).to receive(:run_hook).with('update').and_return([false, ''])
        expect_any_instance_of(Gitlab::Git::HooksService).not_to receive(:run_hook).with('post-receive')
      end

      it 'raises exception' do
        expect { subject.commit }.to raise_error(Gitlab::Git::Wiki::OperationError)
      end

      it 'does not create a new commit inside the repository' do
        current_rev = find_current_rev

        expect { subject.commit }.to raise_error(Gitlab::Git::Wiki::OperationError)

        expect(current_rev).to eq find_current_rev
      end
    end

    shared_examples 'failing post-receive hook' do
      before do
        expect_any_instance_of(Gitlab::Git::HooksService).to receive(:run_hook).with('pre-receive').and_return([true, ''])
        expect_any_instance_of(Gitlab::Git::HooksService).to receive(:run_hook).with('update').and_return([true, ''])
        expect_any_instance_of(Gitlab::Git::HooksService).to receive(:run_hook).with('post-receive').and_return([false, ''])
      end

      it 'does not raise exception' do
        expect { subject.commit }.not_to raise_error
      end

      it 'creates the commit' do
        current_rev = find_current_rev

        subject.commit

        expect(current_rev).not_to eq find_current_rev
      end
    end

    shared_examples 'when hooks call succceeds' do
      let(:hook) { double(:hook) }

      it 'calls the three hooks' do
        expect(Gitlab::Git::Hook).to receive(:new).exactly(3).times.and_return(hook)
        expect(hook).to receive(:trigger).exactly(3).times.and_return([true, nil])

        subject.commit
      end

      it 'creates the commit' do
        current_rev = find_current_rev

        subject.commit

        expect(current_rev).not_to eq find_current_rev
      end
    end

    context 'when creating a page' do
      before do
        project_wiki.create_page('index', 'test content')
      end

      it_behaves_like 'failing pre-receive hook'
      it_behaves_like 'failing update hook'
      it_behaves_like 'failing post-receive hook'
      it_behaves_like 'when hooks call succceeds'
    end

    context 'when updating a page' do
      before do
        project_wiki.update_page(find_page('home'), content: 'some other content', format: :markdown)
      end

      it_behaves_like 'failing pre-receive hook'
      it_behaves_like 'failing update hook'
      it_behaves_like 'failing post-receive hook'
      it_behaves_like 'when hooks call succceeds'
    end

    context 'when deleting a page' do
      before do
        project_wiki.delete_page(find_page('home'))
      end

      it_behaves_like 'failing pre-receive hook'
      it_behaves_like 'failing update hook'
      it_behaves_like 'failing post-receive hook'
      it_behaves_like 'when hooks call succceeds'
    end

    def find_current_rev
      wiki.gollum_wiki.repo.commits.first&.sha
    end

    def find_page(name)
      wiki.page(title: name)
    end
  end

  # context 'when Gitaly is enabled' do
  #   it_behaves_like 'calling wiki hooks'
  # end

  context 'when Gitaly is disabled', :skip_gitaly_mock do
    it_behaves_like 'calling wiki hooks'
  end
end
