# frozen_string_literal: true

RSpec.shared_examples 'updating the container expiration policy attributes' do |mode:, to:, from: {}|
  if mode == :create
    it 'creates a new container expiration policy' do
      expect { subject }
        .to change { project.reload.container_expiration_policy.present? }.from(false).to(true)
        .and change { ContainerExpirationPolicy.count }.by(1)
    end
  else
    it_behaves_like 'not creating the container expiration policy'
  end

  it 'updates the container expiration policy' do
    if from.empty?
      subject

      expect(container_expiration_policy.reload.cadence).to eq(to[:cadence])
      expect(container_expiration_policy.keep_n).to eq(to[:keep_n])
      expect(container_expiration_policy.older_than).to eq(to[:older_than])
    else
      expect { subject }
        .to change { container_expiration_policy.reload.cadence }.from(from[:cadence]).to(to[:cadence])
        .and change { container_expiration_policy.reload.keep_n }.from(from[:keep_n]).to(to[:keep_n])
        .and change { container_expiration_policy.reload.older_than }.from(from[:older_than]).to(to[:older_than])
    end
  end
end

RSpec.shared_examples 'not creating the container expiration policy' do
  it "doesn't create the container expiration policy" do
    expect { subject }.not_to change { ContainerExpirationPolicy.count }
  end
end

RSpec.shared_examples 'creating the container expiration policy' do
  it_behaves_like 'updating the container expiration policy attributes', mode: :create, to: { cadence: '3month', keep_n: 100, older_than: '14d' }

  it_behaves_like 'returning a success'
end
