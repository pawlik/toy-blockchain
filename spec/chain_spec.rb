# frozen_string_literal: true

require './lib/chain.rb'
require './lib/block.rb'

RSpec.describe Chain do
  let(:block_hash) do
    {
      transactions: transactions,
      transactions_hash: transactions_hash,
      timestamp: timestamp,
      allowed_miners: allowed_miners,
      height: height,
      previous_hash: previous_hash,
      signature: ''
    }
  end

  let(:transactions_hash) { TransactionsHash.new(transactions.values.map(&:to_json)).calculate }
  let(:transactions) { {} }
  let(:height) { 0 }
  let(:timestamp) { 123_456 }
  let(:previous_hash) { '' }

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
        timestamp: timestamp + (10 * 60) + 1,
        transactions_hash: TransactionsHash.new(second_block_transactions.values.map(&:to_json)).calculate,
        previous_hash: block.signature
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

  describe "miner's competition" do
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

    context 'when adding genesis block' do
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

      context 'when previous hash is not empty' do
        let(:previous_hash) { 'not empty' }
        specify 'the block is not accepted' do
          expect { subject.add(block) }.to raise_error 'Invalid block (genesis block\'s previous hash is not empty)'
        end
      end

      context 'when adding next block' do
        subject { chain.add(second_block) }

        before do
          chain.add(block)
          second_miner.sign(second_block)
        end

        let(:chain) { Chain.new }
        let(:second_block) { Block.new(second_block_hash) }
        let(:second_miner) { Miner.generate('miner_2') }
        let(:allowed_miners) do
          {
            'miner_1' => { key: miner.public_key.to_s },
            'miner_2' => { key: second_miner.public_key.to_s }
          }
        end

        let(:second_block_hash) do
          {
            transactions: second_transactions,
            transactions_hash: second_transactions_hash,
            timestamp: second_timestamp,
            allowed_miners: more_allowed_miners,
            height: second_height,
            previous_hash: second_previous_hash,
            signature: ''
          }
        end

        let(:more_allowed_miners) { {} }
        let(:second_transactions_hash) { TransactionsHash.new(second_transactions.values.map(&:to_json)).calculate }
        let(:second_transactions) { {} }
        let(:second_height) { 1 }
        let(:second_timestamp) { timestamp + (10 * 60) + 1 } # ten minutes
        let(:second_previous_hash) { block.signature }

        it do
          is_expected.to eq true
        end

        context "the block's height is not 1" do
          let(:second_height) { 0 }
          specify 'the block is not accepted' do
            expect { subject }.to raise_error 'Invalid block (height mismatch)'
          end
        end
        context 'previous hash does not match the origin block' do
          let(:second_previous_hash) { 'foo' }
          specify 'the block is not accepted' do
            expect { subject }.to raise_error 'Invalid block (previous hash does not match)'
          end
        end
        context 'second block is signed by miner not on the list on gensis block' do
          let(:other_miner) { Miner.generate('miner_1') }

          specify 'the block is not accepted'
        end
        context 'second block reward is not 100' do
          let(:second_transactions) do
            {
              '0' => { from: '', to: second_miner.public_key.to_s, amount: 101, payload: '', signature: '' }
            }
          end
          specify 'this block is not accepted' do
            expect { subject }.to raise_error 'Invalid block (wrong miner\'s reward)'
          end
        end
        context 'second block has less than 10 transactions' do
          let(:second_transactions) do
            {
              '0' => { from: '', to: second_miner.public_key.to_s, amount: 100, payload: '', signature: '' }
            }
          end
          context 'when mined sooner than 10 minutes before the previous one' do
            let(:second_timestamp) { timestamp + (5 * 60) }
            specify 'this block is not accepted' do
              expect { subject }.to raise_error 'Invalid block (mined too soon)'
            end
          end
          context 'when mined later than 10 minutes after previous one' do
            specify 'the block is accepted' do
              is_expected.to eq true
            end
          end
        end

        context 'second block is mined with 10 transactions' do
          let(:second_transactions) do
            (1..10).map do |i|
              [i.to_s, { from: miner.public_key.to_s, to: second_miner.public_key.to_s, amount: 5, payload: '', signature: '' }]
            end.to_h
          end
          context 'when mined sooner than 10 minutes after the previous one' do
            let(:second_timestamp) { timestamp + 1 }
            specify 'the block is accepted' do
              is_expected.to eq true
            end
          end
          context 'when mined later 10 minutes after previous one' do
            specify 'the block is accepted' do
              is_expected.to eq true
            end
          end
        end
      end

      context "when miner's reward is not 100" do
        let(:mining_reward) { 101 }

        specify do
          expect { subject.add(block) }.to raise_error 'Invalid block (wrong miner\'s reward)'
        end
      end

      context 'when height is not 0' do
        let(:height) { 1 }
        specify 'such block is not valid' do
          expect { subject.add(block) }.to raise_error 'Invalid block (height mismatch)'
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
