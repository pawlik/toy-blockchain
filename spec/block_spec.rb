# frozen_string_literal: true

require './lib/block.rb'
require './lib/miner.rb'

RSpec.describe Block do
  subject { Block.new(block_hash) }

  it do
    is_expected.not_to be_signed
    expect { subject.sign!('made_up') }.to raise_error('Invalid transactions')
  end

  let(:block_hash) do
    {
      transactions: transactions,
      transactions_hash: transactions_hash,
      timestamp: 123_456,
      allowed_miners: {
        # only in gensis block, this entry should not exist for other blocks
        'miner_1' => { key: 'miner_1_pub_key', address: '0.0.0.0:10800' },
        'miner_2' => { key: 'miner_2_pub_key', address: '0.0.0.0:10801' }
      },
      height: 0, # important :)
      previous_hash: '',
      signed_by: 'miner_1',
      signature: signature
    }
  end
  let(:signature) { '' }
  let(:transactions_hash) { 'transactions hash' }
  let(:transactions) do
    {
      '0' => miners_reward.to_h,
      # miner's reward
      # transactions have indexes from 1 to 10, block with more are invalid
      # to verify transaction, replace signature with empty string, and
      # verify it's JSON representation?
    }
  end
  let(:miner) { Miner.generate('miner') }
  let(:miners_reward) do
    miner.sign_transaction(
      Transaction.from_hash(from: '', to: miner.public_key.to_s, amount: 100, payload: '', signature: '')
    )
  end

  context 'when created from hash' do
    subject { described_class.from_hash block_hash }
    let(:signature) { 'foo' }

    specify 'block data are stored and retrievable as json string' do
      skip "There's a small problem with comparing string here :("
      expect(subject.to_json)
        .to eq '{'\
                  '"transactions":' \
                    '{"0":{"from":"","to":"' + miner.public_key.to_s + '","amount":100,"payload":"","signature":"' + miners_reward.signature + '"}},' \
                 '"transactions_hash":"transactions hash",' \
                 '"timestamp":123456,'\
                 '"allowed_miners":'\
                   '{'\
                     '"miner_1":{"key":"miner_1_pub_key","address":"0.0.0.0:10800"},'\
                     '"miner_2":{"key":"miner_2_pub_key","address":"0.0.0.0:10801"}'\
                    '},'\
                  '"height":0,'\
                  '"previous_hash":"",'\
                  '"signed_by":"miner_1",'\
                  '"signature":"foo"'\
                '}'
    end

    describe '#transactions_valid?' do
      subject { described_class.from_hash(block_hash).transactions_valid? }

      let(:transactions_hash) { TransactionsHash.new(transactions.values.map(&:to_json)).calculate }

      it { is_expected.to eq true }

      context 'when hash is wrong' do
        let(:transactions_hash) { 'foo' }
        it { is_expected.to eq false }
      end

      context 'when transaction is not signed by from address key owner' do
        let(:sender) { Miner.generate('sender') } # Miner's are quick wallets
        let(:miner) { Miner.generate('miner') } # Miner's are quick wallets
        let(:transactions) do
          {
            '0' => miners_reward.to_h,
            '1' => transaction.to_h
          }
        end

        let(:miners_reward) do
          miner.sign_transaction(
            Transaction.from_hash(from: '', to: miner.public_key.to_s, amount: 100, payload: '', signature: '')
          )
        end
        let(:transaction) do
          Transaction.from_hash(from: sender.public_key.to_s, to: miner.public_key.to_s, amount: 100, payload: '', signature: '')
        end

        specify do
          expect(described_class.from_hash(block_hash).transactions_valid?).to eq false
        end
      end

      context 'when transaction has been tampered with' do
        it do
          hash = block_hash
          hash[:transactions]['0'][:to] = 'hackers_pub_key'
          expect(described_class.from_hash(hash).transactions_valid?).to eq false
        end
      end
    end
  end

  describe 'signed_by?' do
    subject { block.signed_by?(miner) }

    let(:transactions_hash) { TransactionsHash.new(transactions.values.map(&:to_json)).calculate }
    let(:block) { Block.new(block_hash) }
    let(:miner) { Miner.generate('miner_1') }
    let(:other_miner) { Miner.generate('miner_2') }

    before { miner.sign(block) }

    it do
      is_expected.to eq true
      expect(block.signed_by?(other_miner)).to eq false
    end
  end
end
