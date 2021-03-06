# frozen_string_literal: true

require 'json'
require_relative 'transactions_hash.rb'
require_relative 'transaction.rb'
# TODO: add some desc later
# Block class
class Block
  attr_reader :transactions
  attr_reader :allowed_miners
  attr_reader :height
  attr_reader :signature
  attr_reader :previous_hash
  attr_reader :timestamp
  attr_accessor :signed_by

  def signed?
    !(@signature.nil? || @signature.empty?)
  end

  def sign!(signature)
    raise 'Invalid transactions' unless transactions_valid?
    @signature = signature
  end

  def unsign!
    s = @signature
    @signature = ''
    s
  end

  def signed_by?(miner)
    miner.signed_by_self?(self)
  end

  def initialize(hash = {})
    @signature = hash.fetch(:signature)
    @transactions = hash.fetch(:transactions).map do |k, v|
      [k, Transaction.from_hash(v)]
    end.to_h
    @transactions_hash = hash.fetch(:transactions_hash)
    @timestamp = hash.fetch(:timestamp)
    @allowed_miners = hash.fetch(:allowed_miners)
    @height = hash.fetch(:height)
    @previous_hash = hash.fetch(:previous_hash)
    @signed_by = hash.fetch(:signed_by, nil)
    @signature = hash.fetch(:signature, nil)
  end

  def self.from_hash(hash)
    new(hash)
  end

  # The real implementation
  # would need canonical block as string representation
  # right now we assume that to_json does not change the order of stuff
  def to_json
    {
      transactions: @transactions.map { |k, v| [k, v.to_h] }.to_h,
      transactions_hash: @transactions_hash,
      timestamp: @timestamp,
      allowed_miners: @allowed_miners,
      height: @height,
      previous_hash: @previous_hash,
      signed_by: @signed_by,
      signature: @signature
    }.to_json
  end

  def transactions_valid?
    hash_valid? && transactions_correctly_signed?
  end

  def transactions_correctly_signed?
    @transactions.values.reject(&:miners_reward?).all?(&:signed?)
  end

  def hash_valid?
    @transactions_hash == TransactionsHash.new(@transactions.values.map(&:to_json)).calculate
  end
end
