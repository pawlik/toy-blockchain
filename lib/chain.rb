# frozen_string_literal: true

require './lib/miner.rb'

class Chain
  MINER_REWARD = 100

  def add(block)
    @the_chain ||= []
    raise 'Invalid block' unless block.signed?
    assert_signed_by_approved_miners(block)
    validate_transactions!(block)
    update_balances!(block)
    @the_chain << block
    true
  end

  def size
    @the_chain.size
  end

  def balance(pkey)
    @balances[pkey]
  end

  def initialize
    @balances = {}
  end

  private

  def update_balances!(block)
    block.transactions.each do |index, transaction|
      if transaction.from == '' && index == '0'
        @balances[transaction.to] = (@balances[transaction.to] || 0.0) + transaction.amount
      else
        balance_from = @balances[transaction.from] || 0
        raise 'Overspending!' if balance_from < transaction.amount
        @balances[transaction.to] = (@balances[transaction.to] || 0.0) + transaction.amount
        @balances[transaction.from] -= transaction.amount
      end
    end
  end

  def validate_transactions!(block)
    block.transactions.each do |index, transaction|
      raise 'Invalid block' if index == '0' && transaction.amount != MINER_REWARD
    end
  end

  def assert_signed_by_approved_miners(block)
    genesis_block = @the_chain.first || block
    pkey = OpenSSL::PKey::RSA.new(genesis_block.allowed_miners[block.signed_by][:key])
    miner = Miner.new(pkey, block.signed_by)
    raise 'Invalid block (miner\'s key not found on the list)' unless miner.signed_by_self?(block)
  end
end
