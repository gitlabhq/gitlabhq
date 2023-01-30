# frozen_string_literal: true

RSpec.shared_examples 'matches_cross_reference_regex? fails fast' do
  it 'fails fast for long strings' do
    # took well under 1 second in CI https://dev.gitlab.org/gitlab/gitlabhq/merge_requests/3267#note_172823
    expect do
      Timeout.timeout(6.seconds) { mentionable.matches_cross_reference_regex? }
    end.not_to raise_error
  end
end

RSpec.shared_examples 'validates description length with custom validation' do
  let(:invalid_description) { 'x' * (::Issuable::DESCRIPTION_LENGTH_MAX + 1) }
  let(:valid_description) { 'short description' }
  let(:issuable) { build(:issue, description: description) }

  let(:error_message) do
    format(
      _('is too long (%{size}). The maximum size is %{max_size}.'),
      size: ActiveSupport::NumberHelper.number_to_human_size(invalid_description.bytesize),
      max_size: ActiveSupport::NumberHelper.number_to_human_size(::Issuable::DESCRIPTION_LENGTH_MAX)
    )
  end

  subject(:validate) { issuable.validate(context) }

  context 'when Issuable is a new record' do
    let(:context) { :create }

    context 'when description exceeds the maximum size' do
      let(:description) { invalid_description }

      it 'adds a description too long error' do
        validate

        expect(issuable.errors[:description]).to contain_exactly(error_message)
      end
    end

    context 'when description is within the allowed limits' do
      let(:description) { valid_description }

      it 'does not add a validation error' do
        validate

        expect(issuable.errors).not_to have_key(:description)
      end
    end
  end

  context 'when Issuable is an existing record' do
    let(:context) { :update }

    before do
      allow(issuable).to receive(:expire_etag_cache) # to skip the expire_etag_cache callback

      issuable.description = existing_description
      issuable.save!(validate: false)
      issuable.description = description
    end

    context 'when record already had a valid description' do
      let(:existing_description) { 'small difference so it triggers description_changed?' }

      context 'when new description exceeds the maximum size' do
        let(:description) { invalid_description }

        it 'adds a description too long error' do
          validate

          expect(issuable.errors[:description]).to contain_exactly(error_message)
        end
      end

      context 'when new description is within the allowed limits' do
        let(:description) { valid_description }

        it 'does not add a validation error' do
          validate

          expect(issuable.errors).not_to have_key(:description)
        end
      end
    end

    context 'when record existed with an invalid description' do
      let(:existing_description) { "#{invalid_description} small difference so it triggers description_changed?" }

      context 'when description is not changed' do
        let(:description) { existing_description }

        it 'does not add a validation error' do
          validate

          expect(issuable.errors).not_to have_key(:description)
        end
      end

      context 'when new description exceeds the maximum size' do
        let(:description) { invalid_description }

        it 'allows updating descriptions that already existed above the limit' do
          validate

          expect(issuable.errors).not_to have_key(:description)
        end
      end

      context 'when new description is within the allowed limits' do
        let(:description) { valid_description }

        it 'does not add a validation error' do
          validate

          expect(issuable.errors).not_to have_key(:description)
        end
      end
    end
  end
end

RSpec.shared_examples 'truncates the description to its allowed maximum length on import' do
  before do
    allow(issuable).to receive(:importing?).and_return(true)
  end

  let(:issuable) { build(:issue, description: 'x' * (::Issuable::DESCRIPTION_LENGTH_MAX + 1)) }

  subject { issuable.validate(:create) }

  it 'truncates the description to its allowed maximum length' do
    subject

    expect(issuable.description).to eq('x' * ::Issuable::DESCRIPTION_LENGTH_MAX)
    expect(issuable.errors[:description]).to be_empty
  end
end
