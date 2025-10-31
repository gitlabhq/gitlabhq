# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ReleasesImporter, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled
    )
  end

  let_it_be(:placeholder_user) { create(:user, :placeholder) }
  let_it_be(:author) do
    {
      login: 'User A',
      id: 1
    }
  end

  let(:client) { instance_double(Gitlab::GithubImport::Client, web_endpoint: 'https://github.com') }
  let(:github_release_name) { 'Initial Release' }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:released_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:body) { 'This is my release' }
  let(:cached_references) { placeholder_user_references(::Import::SOURCE_GITHUB, project.import_state.id) }
  let(:github_release) do
    {
      id: 123456,
      tag_name: '1.0',
      name: github_release_name,
      body: body,
      created_at: created_at,
      published_at: released_at,
      author: author
    }
  end

  subject(:importer) { described_class.new(project, client) }

  context 'when user mapping is enabled', :clean_gitlab_redis_shared_state do
    let_it_be(:source_user) { generate_source_user(project, 1, placeholder_user: placeholder_user) }

    describe '#execute' do
      before do
        allow(importer).to receive(:each_release).and_return([github_release])
      end

      it 'imports the releases in bulk' do
        expect(importer).to receive(:bulk_insert).and_call_original

        expect { importer.execute }.to change { Release.count }.by(1)

        expect(project.releases.last).to have_attributes(
          name: github_release_name,
          tag: '1.0',
          author_id: source_user.mapped_user_id,
          description: body,
          created_at: created_at,
          updated_at: created_at,
          released_at: released_at
        )
      end

      it 'pushes placeholder references' do
        importer.execute

        expect(cached_references).to contain_exactly(
          ['Release', project.releases.last.id, 'author_id', source_user.id]
        )
      end

      context 'when the release is a draft', :freeze_time do
        let(:released_at) { nil }

        it 'imports the release' do
          expect { importer.execute }.to change { Release.count }.by(1)

          expect(project.releases.last).to have_attributes(
            name: github_release_name,
            tag: '1.0',
            author_id: source_user.mapped_user_id,
            description: body,
            created_at: created_at,
            updated_at: created_at,
            released_at: Time.current
          )
        end
      end

      it 'is idempotent' do
        expect { importer.execute }.to change { Release.count }.by(1)
        expect { importer.execute }.not_to change { Release.count } # Idempotency check
      end

      context 'when the body has user mentions' do
        let(:body) { 'You can ask @knejad by emailing xyz@gitlab.com' }

        it 'adds backticks to the username' do
          allow(importer).to receive(:each_release).and_return([github_release])

          importer.execute

          expect(Release.last.description).to eq("You can ask `@knejad` by emailing xyz@gitlab.com")
        end
      end

      context 'when importing into a personal namespace' do
        let_it_be(:user_namespace) { create(:namespace) }

        before_all do
          project.update!(namespace: user_namespace)
        end

        it 'does not push any references' do
          importer.execute

          expect(cached_references).to be_empty
        end

        it 'imports the release mapped to the personal namespace owner' do
          importer.execute

          expect(project.releases.last.author_id).to eq(user_namespace.owner_id)
        end

        context 'when user_mapping_to_personal_namespace_owner is disabled' do
          let_it_be(:source_user) { generate_source_user(project, 1) }

          before_all do
            project.build_or_assign_import_data(
              data: { user_mapping_to_personal_namespace_owner_enabled: false }
            ).save!
          end

          it 'pushes placeholder references' do
            importer.execute

            expect(cached_references).to contain_exactly(
              ['Release', project.releases.last.id, 'author_id', source_user.id]
            )
          end

          it 'imports the release mapped to the placeholder user' do
            importer.execute

            expect(project.releases.last.author_id).to eq(source_user.mapped_user_id)
          end
        end
      end
    end

    describe '#build_releases' do
      it 'returns an Array containing release rows' do
        expect(importer).to receive(:each_release).and_return([github_release])

        rows, errors = importer.build_releases

        expect(rows.length).to eq(1)
        expect(rows[0][:tag]).to eq('1.0')
        expect(errors).to be_empty
      end

      it 'does not create releases that already exist' do
        create(:release, project: project, tag: '1.0', description: '1.0')

        expect(importer).to receive(:each_release).and_return([github_release])

        rows, errors = importer.build_releases

        expect(rows).to be_empty
        expect(errors).to be_empty
      end

      it 'uses a default release description if none is provided' do
        github_release[:body] = nil
        expect(importer).to receive(:each_release).and_return([github_release])

        release, _ = importer.build_releases.first

        expect(release[:description]).to eq('Release for tag 1.0')
      end

      it 'does not create releases that have a NULL tag' do
        null_tag_release = {
          name: 'NULL Test',
          tag_name: nil
        }

        expect(importer).to receive(:each_release).and_return([null_tag_release])

        rows, errors = importer.build_releases

        expect(rows).to be_empty
        expect(errors).to be_empty
      end

      it 'does not create duplicate release tags' do
        expect(importer).to receive(:each_release).and_return([github_release, github_release])

        releases, _ = importer.build_releases
        expect(releases.length).to eq(1)
        expect(releases[0][:description]).to eq('This is my release')
      end

      it 'does not create invalid release' do
        github_release[:body] = SecureRandom.alphanumeric(Gitlab::Database::MAX_TEXT_SIZE_LIMIT + 1)

        expect(importer).to receive(:each_release).and_return([github_release])

        releases, errors = importer.build_releases

        expect(releases).to be_empty
        expect(errors.length).to eq(1)
        expect(errors[0][:validation_errors].full_messages).to match_array(
          ['Description is too long (maximum is 1000000 characters)']
        )
        expect(errors[0][:external_identifiers]).to eq({ tag: '1.0', object_type: :release })
      end
    end

    describe '#build_attributes' do
      let(:release_hash) { importer.build_attributes(github_release) }

      context 'the returned Hash' do
        it 'returns the attributes of the release as a Hash' do
          expect(release_hash).to be_an_instance_of(Hash)
        end

        it 'includes the tag name' do
          expect(release_hash[:tag]).to eq('1.0')
        end

        it 'includes the release description' do
          expect(release_hash[:description]).to eq('This is my release')
        end

        it 'includes the project ID' do
          expect(release_hash[:project_id]).to eq(project.id)
        end

        it 'includes the created timestamp' do
          expect(release_hash[:created_at]).to eq(created_at)
        end

        it 'includes the updated timestamp' do
          expect(release_hash[:updated_at]).to eq(created_at)
        end

        it 'includes the release name' do
          expect(release_hash[:name]).to eq(github_release_name)
        end
      end

      context 'author_id attribute' do
        it 'returns the Gitlab user_id when Github release author is found' do
          expect(release_hash[:author_id]).to eq(placeholder_user.id)
        end

        it 'returns ghost user when author is empty in Github release' do
          github_release[:author] = nil
          ghost_author = { id: Gitlab::GithubImport.ghost_user_id(project.organization), login: 'ghost' }

          expect(release_hash[:author_id]).to eq(Gitlab::GithubImport.ghost_user_id(project.organization))
          expect(importer.github_users).to eq([ghost_author])
        end
      end

      context 'github user ids' do
        it 'builds the github_users array' do
          release_hash
          expect(importer.github_users).to eq([github_release[:author]])
        end
      end
    end

    describe '#each_release' do
      let(:github_release) { double(:github_release) }

      before do
        allow(project).to receive(:import_source).and_return('foo/bar')

        allow(client)
          .to receive(:releases)
          .with('foo/bar')
          .and_return([github_release].to_enum)
      end

      it 'returns an Enumerator' do
        expect(importer.each_release).to be_an_instance_of(Enumerator)
      end

      it 'yields every release to the Enumerator' do
        expect(importer.each_release.next).to eq(github_release)
      end
    end

    describe '#description_for' do
      it 'returns the description when present' do
        expect(importer.description_for(github_release)).to eq(github_release[:body])
      end

      it 'returns a generated description when one is not present' do
        github_release[:body] = nil

        expect(importer.description_for(github_release)).to eq('Release for tag 1.0')
      end
    end
  end

  context 'when user mapping is disabled' do
    let_it_be(:user) { create(:user, username: author[:login]) }

    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!

      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |instance|
        allow(instance).to receive(:email_for_github_username)
          .with(user.username).and_return(user.email)
      end
    end

    describe '#execute' do
      before do
        allow(importer).to receive(:each_release).and_return([github_release])
      end

      it 'imports the releases in bulk' do
        expect(importer).to receive(:bulk_insert).and_call_original

        expect { importer.execute }.to change { Release.count }.by(1)

        expect(project.releases.last).to have_attributes(
          name: github_release_name,
          tag: '1.0',
          author_id: user.id,
          description: body,
          created_at: created_at,
          updated_at: created_at,
          released_at: released_at
        )
      end

      it 'does not push placeholder references' do
        importer.execute

        expect(cached_references).to be_empty
      end

      context 'when the release is a draft', :freeze_time do
        let(:released_at) { nil }

        it 'imports the release' do
          expect { importer.execute }.to change { Release.count }.by(1)

          expect(project.releases.last).to have_attributes(
            name: github_release_name,
            tag: '1.0',
            author_id: user.id,
            description: body,
            created_at: created_at,
            updated_at: created_at,
            released_at: Time.current
          )
        end
      end

      it 'is idempotent' do
        expect { importer.execute }.to change { Release.count }.by(1)
        expect { importer.execute }.not_to change { Release.count } # Idempotency check
      end

      context 'when the body has user mentions' do
        let(:body) { 'You can ask @knejad by emailing xyz@gitlab.com' }

        it 'adds backticks to the username' do
          allow(importer).to receive(:each_release).and_return([github_release])

          importer.execute

          expect(Release.last.description).to eq("You can ask `@knejad` by emailing xyz@gitlab.com")
        end
      end
    end

    describe '#build_releases' do
      it 'returns an Array containing release rows' do
        expect(importer).to receive(:each_release).and_return([github_release])

        rows, errors = importer.build_releases

        expect(rows.length).to eq(1)
        expect(rows[0][:tag]).to eq('1.0')
        expect(errors).to be_empty
      end

      it 'does not create releases that already exist' do
        create(:release, project: project, tag: '1.0', description: '1.0')

        expect(importer).to receive(:each_release).and_return([github_release])

        rows, errors = importer.build_releases

        expect(rows).to be_empty
        expect(errors).to be_empty
      end

      it 'uses a default release description if none is provided' do
        github_release[:body] = nil
        expect(importer).to receive(:each_release).and_return([github_release])

        release, _ = importer.build_releases.first

        expect(release[:description]).to eq('Release for tag 1.0')
      end

      it 'does not create releases that have a NULL tag' do
        null_tag_release = {
          name: 'NULL Test',
          tag_name: nil
        }

        expect(importer).to receive(:each_release).and_return([null_tag_release])

        rows, errors = importer.build_releases

        expect(rows).to be_empty
        expect(errors).to be_empty
      end

      it 'does not create duplicate release tags' do
        expect(importer).to receive(:each_release).and_return([github_release, github_release])

        releases, _ = importer.build_releases
        expect(releases.length).to eq(1)
        expect(releases[0][:description]).to eq('This is my release')
      end

      it 'does not create invalid release' do
        github_release[:body] = SecureRandom.alphanumeric(Gitlab::Database::MAX_TEXT_SIZE_LIMIT + 1)

        expect(importer).to receive(:each_release).and_return([github_release])

        releases, errors = importer.build_releases

        expect(releases).to be_empty
        expect(errors.length).to eq(1)
        expect(errors[0][:validation_errors].full_messages).to match_array(
          ['Description is too long (maximum is 1000000 characters)']
        )
        expect(errors[0][:external_identifiers]).to eq({ tag: '1.0', object_type: :release })
      end
    end

    describe '#build_attributes' do
      let(:release_hash) { importer.build_attributes(github_release) }

      context 'the returned Hash' do
        it 'returns the attributes of the release as a Hash' do
          expect(release_hash).to be_an_instance_of(Hash)
        end

        it 'includes the tag name' do
          expect(release_hash[:tag]).to eq('1.0')
        end

        context 'when the description is processed for formatting' do
          let(:body) { "I said to @sam_allen\0 the code should follow @bob's\0 advice. @.ali-ce/group#9?\0" }
          let(:expected_body) { "I said to `@sam_allen` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?" }

          before do
            allow(Gitlab::GithubImport::MarkdownText).to receive(:format).and_call_original

            release_hash
          end

          it 'verify that the formatted description using MarkdownText equals the expected description' do
            expect(Gitlab::GithubImport::MarkdownText).to have_received(:format)
            expect(release_hash[:description]).to eq(expected_body)
          end
        end

        it 'includes the project ID' do
          expect(release_hash[:project_id]).to eq(project.id)
        end

        it 'includes the created timestamp' do
          expect(release_hash[:created_at]).to eq(created_at)
        end

        it 'includes the updated timestamp' do
          expect(release_hash[:updated_at]).to eq(created_at)
        end

        it 'includes the release name' do
          expect(release_hash[:name]).to eq(github_release_name)
        end
      end

      context 'author_id attribute' do
        it 'returns the Gitlab user_id when Github release author is found' do
          # Disable cache read as the redis cache key can be set by other specs.
          # https://gitlab.com/gitlab-org/gitlab/-/blob/88bffda004e0aca9c4b9f2de86bdbcc0b49f2bc7/lib/gitlab/github_import/user_finder.rb#L75
          # Above line can return different user when read from cache.
          allow(Gitlab::Cache::Import::Caching).to receive(:read).and_return(nil)

          expect(release_hash[:author_id]).to eq(user.id)
        end

        it 'returns ghost user when author is empty in Github release' do
          github_release[:author] = nil

          expect(release_hash[:author_id]).to eq(Gitlab::GithubImport.ghost_user_id(project.organization))
        end

        context 'when Github author is not found in Gitlab' do
          let(:author) { { login: 'octocat', id: 1 } }

          before do
            # Stub user email which does not match a Gitlab user.
            allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |instance|
              allow(instance).to receive(:email_for_github_username)
                .with('octocat').and_return('octocat@example.com')
            end
          end

          it 'returns project creator as author' do
            expect(release_hash[:author_id]).to eq(project.creator_id)
          end
        end
      end
    end

    describe '#each_release' do
      let(:github_release) { double(:github_release) }

      before do
        allow(project).to receive(:import_source).and_return('foo/bar')

        allow(client)
          .to receive(:releases)
          .with('foo/bar')
          .and_return([github_release].to_enum)
      end

      it 'returns an Enumerator' do
        expect(importer.each_release).to be_an_instance_of(Enumerator)
      end

      it 'yields every release to the Enumerator' do
        expect(importer.each_release.next).to eq(github_release)
      end
    end

    describe '#description_for' do
      it 'returns the description when present' do
        expect(importer.description_for(github_release)).to eq(github_release[:body])
      end

      it 'returns a generated description when one is not present' do
        github_release[:body] = nil

        expect(importer.description_for(github_release)).to eq('Release for tag 1.0')
      end
    end
  end
end
