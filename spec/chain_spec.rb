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
      signature: ''
    }
  end

  let(:transactions_hash) { TransactionsHash.new(transactions.values.map(&:to_json)).calculate }
  let(:transactions) { {} }
  let(:height) { 0 }

  describe '#balance' do
    let(:chain) { Chain.new }
    let(:miner) { Miner.generate('miner_1') }
    let(:other_miner) { Miner.generate('miner_2') }
    let(:wallet) { Miner.generate('some_wallet') }
    let(:transactions) do
      {
        '0' => { from: '', to: miner.public_key.to_s, amount: 100, payload: '', signature: '' }
      }
    end

    let(:allowed_miners) do
      {
        'miner_1' => { key: miner.public_key.to_s },
        'miner_2' => { key: other_miner.public_key.to_s }
      }
    end

    let(:block) { Block.new(block_hash) }

    let(:second_block) do
      Block.new block_hash.merge(
        transactions: second_block_transactions,
        height: 1,
        transactions_hash: TransactionsHash.new(second_block_transactions.values.map(&:to_json)).calculate
      )
    end
    let(:second_block_transactions) do
      {
        '0' => { from: '', to: other_miner.public_key.to_s, amount: 100, payload: '', signature: '' },
        '1' => { from: miner.public_key.to_s, to: wallet.public_key.to_s, amount: 75, payload: '', signature: '' }
      }
    end

    before do
      chain.add(miner.sign(block))
      chain.add(other_miner.sign(second_block))
    end

    specify do
      expect(chain.balance(miner.public_key.to_s)).to eq 25
      expect(chain.balance(wallet.public_key.to_s)).to eq 75
      expect(chain.balance(other_miner.public_key.to_s)).to eq 100
    end
  end

  describe '#add' do
    subject { Chain.new }
    let(:block) { Block.new(block_hash) }
    let(:miner) { Miner.generate('miner_1') }

    context 'the signed genesis block can be added' do
      let(:height) { 0 }
      let(:transactions) do
        {
          '0' => { from: '', to: miner.public_key.to_s, amount: mining_reward, payload: '', signature: '' }
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
            'miner_1' => { key: Miner.generate('miner_1').public_key.to_s },
            'miner_2' => { key: Miner.generate('miner_2').public_key.to_s }
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
