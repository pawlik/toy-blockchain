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

  desctibe "miner's competition" do
    # Maybe we can assume that miner's will be always online and have one sign odd, and the other
    # even blocks. But then it makes not much sense to have two miners. 

    # Maybe we can have one master, and one slave. Add master block immediatelly. When we don't here from 
    # master - we add slave's N block only when we hear aboyt N+1 block (from slave/or master).
    # This way master can become offline, but slave will not compete with him when minor connection issue
    # occurs. 

    # If both miner's are offline, but some wallets/nodes hear only from master, and some only from slave
    # (network partition?), then after the issue is gone - the `master` nodes will have longer chain (by one)
    # and the competition will be resolved?
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

      context 'adding next block' do
        before { subject.add(block) }

        let(:second_block) { Block.new(second_block_hash) }

        context "the block's height is not 1" do
          specify 'the block is not accepted'
        end
        context 'second block is not on the list on gensis block' do
          specify 'the block is not accepted'
        end
        context 'second block reward is not 100' do
          specify 'this block is not accepted'
        end
        context 'second block has less than 10 transactions' do
          context 'when mined sooner than 10 minutes before the previous one' do
            specify 'this block is not accepted'
          end
          context 'when mined later than 10 minutes after previous one' do
            specify 'the block is accepted'
          end
        end

        context 'second block is mined with 10 transactions' do
          context 'when mined sooner than 10 minutes after the previous one' do
            specify 'the block is accepted'
          end
          context 'when mined later 10 minutes after previous one' do
            specify 'the block is accepted'
          end
        end

        context 'second block has information about additional miners' do
          specify 'block signed by those miner are not accepted'
        end
      end

      context "when miner's reward is not 100" do
        let(:mining_reward) { 101 }

        specify do
          expect { subject.add(block) }.to raise_error 'Invalid block'
        end
      end

      context 'when height is not 0' do
        specify 'such block is not valid'
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
