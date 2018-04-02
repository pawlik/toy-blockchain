# frozen_string_literal: true

require './lib/miner.rb'
require './lib/block.rb'

RSpec.describe Miner do
  # subject { Miner.new(private_key) }

  # let(:rsa_pair) { OpenSSL::PKey::RSA.genrate }
  # let(:public_key) { rsa_pair.public_key }

  # subject.mine(block, previous_block = nil) # => signed block

  # Miner.verify(block, previous_block, miners_public_key)

  describe '.generate' do
    subject { described_class.generate('foo') }

    specify 'generated miner has public key' do
      expect(subject.public_key.to_s).not_to be_empty
    end
  end

  describe '#mine' do
    subject { miner.sign(block) }
    let(:block) { Block.new(block_hash) }
    let(:miner) { described_class.generate('foo') }

    let(:block_hash) do
      {
        transactions: transactions,
        transactions_hash: transactions_hash,
        timestamp: 123_456,
        allowed_miners: {},
        height: 0, # important :)
        previous_hash: '',
        signature: ''
      }
    end
    let(:transactions_hash) { 'transactions hash' }
    let(:transactions) { {} }

    specify { expect { subject }.to raise_error('Invalid block') }

    context "block's transactions are correctly signed" do
      let(:transactions_hash) { TransactionsHash.new(transactions.map(&:to_json)).calculate }

      specify do
        expect { subject }.to change(block, :signed?).from(false).to(true)
        expect(miner.signed_by_self?(block)).to eq true
      end
      it { is_expected.to be_an_instance_of(Block) }
      it { is_expected.to be_signed }
    end
  end
end
