# frozen_string_literal: true

RSpec.shared_examples 'a valid diff positionable note' do |factory_on_commit|
  context 'for commit' do
    let(:project) { create(:project, :repository) }
    let(:commit) { project.commit(sample_commit.id) }
    let(:commit_id) { commit.id }
    let(:diff_refs) { commit.diff_refs }

    let(:position) do
      Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        line_range: nil,
        diff_refs: diff_refs
      )
    end

    context 'position diff refs matches commit diff refs' do
      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors).not_to have_key(:commit_id)
      end
    end

    context 'position diff refs does not match commit diff refs' do
      let(:diff_refs) do
        Gitlab::Diff::DiffRefs.new(
          base_sha: "not_existing_sha",
          head_sha: "existing_sha"
        )
      end

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors).to have_key(:commit_id)
      end
    end

    context 'commit does not exist' do
      let(:commit_id) { 'non-existing' }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors).to have_key(:commit_id)
      end
    end

    %i[original_position position change_position].each do |method|
      describe "#{method}=" do
        it "doesn't accept non-hash JSON passed as a string" do
          subject.send(:"#{method}=", "true")
          expect(subject.attributes_before_type_cast[method.to_s]).to be(nil)
        end

        it "does accept a position hash as a string" do
          subject.send(:"#{method}=", position.to_json)
          expect(subject.position).to eq(position)
        end

        it "doesn't accept an array" do
          subject.send(:"#{method}=", ["test"])
          expect(subject.attributes_before_type_cast[method.to_s]).to be(nil)
        end

        it "does accept a hash" do
          subject.send(:"#{method}=", position.to_h)
          expect(subject.position).to eq(position)
        end
      end
    end

    describe 'schema validation' do
      where(:position_attrs) do
        [
          { old_path: SecureRandom.alphanumeric(1001) },
          { new_path: SecureRandom.alphanumeric(1001) },
          { old_line: "foo" }, # this should be an integer
          { new_line: "foo" }, # this should be an integer
          { line_range: { foo: "bar" } },
          { line_range: { line_code: SecureRandom.alphanumeric(101) } },
          { line_range: { type: SecureRandom.alphanumeric(101) } },
          { line_range: { old_line: "foo" } },
          { line_range: { new_line: "foo" } }
        ]
      end

      with_them do
        let(:position) do
          Gitlab::Diff::Position.new(
            {
              old_path: "files/ruby/popen.rb",
              new_path: "files/ruby/popen.rb",
              old_line: nil,
              new_line: 14,
              line_range: nil,
              diff_refs: diff_refs
            }.merge(position_attrs)
          )
        end

        it { is_expected.to be_invalid }
      end
    end
  end
end
