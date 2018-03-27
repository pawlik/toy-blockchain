require './lib/miner.rb'

RSpec.describe Miner do
  # subject { Miner.new(private_key) }

  # let(:rsa_pair) { OpenSSL::PKey::RSA.genrate }
  # let(:public_key) { rsa_pair.public_key }

  # subject.mine(block, previous_block = nil) # => signed block

  # Miner.verify(block, previous_block, miners_public_key)

  context '.generate' do
    subject { described_class.generate }

    specify 'generated miner has public key' do
      expect(subject.public_key.to_s).not_to be_empty
    end
  end
end
