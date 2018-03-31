# frozen_string_literal: true

require './lib/chain.rb'
require './lib/block.rb'

RSpec.describe Chain do
  let(:block_hash) do
    {
      transactions: transactions,
      transactions_hash: transactions_hash,
      timestamp: 123_456,
      allowed_miners: allowed_miners,
      height: height,
      previous_hash: '',
      signed_by: signed_by,
      signature: ''
    }
  end
  let(:signed_by) { 'miner_1' }
  let(:transactions_hash) { TransactionsHash.new(transactions.values.map(&:to_json)).calculate }
  let(:transactions) { {} }

  describe '#add' do
    subject { Chain.new }
    let(:block) { Block.new(block_hash) }
    let(:miner) { Miner.generate }

    context 'the signed genesis block can be added' do
      let(:height) { 0 }
      let(:transactions) do
        {
          '0' => { from: '', to: miner.public_key, amount: mining_reward, payload: '', signature: '' }
        }
      end
      let(:mining_reward) { 100 }
      let(:allowed_miners) do
        {
          'miner_1' => { key: miner.public_key.to_s }
        }
      end

      before { miner.sign(block) }

      specify do
        expect(subject.add(block)).to eq true
        expect(subject.size).to eq 1
      end

      context "when miner's reward is not 100" do
        let(:mining_reward) { 101 }

        specify do
          expect { subject.add(block) }.to raise_error 'Invalid block'
        end
      end

      context 'when gensis block is signed by different miner than specified in genesis block' do
        let(:allowed_miners) do
          {
            'miner_1' => { key: Miner.generate.public_key.to_s },
            'miner_2' => { key: Miner.generate.public_key.to_s }
          }
        end

        specify do
          expect { subject.add(block) }
            .to raise_error 'Invalid block (miner\'s key not found on the list)'
        end
      end
    end
  end
end
