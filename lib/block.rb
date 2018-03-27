# frozen_string_literal: true

require 'json'
require_relative 'transactions_hash.rb'
# TODO: add some desc later
# Block class
class Block
  def signed?
    !(@signature.nil? || @signature.empty?)
  end

  def sign!(signature)
    @signature = signature
  end

  def initialize(hash = {})
    @signature = hash[:signature]
    @transactions = hash[:transactions]
    @transactions_hash = hash[:transactions_hash]
    @timestamp = hash[:timestamp]
    @allowed_miners = hash[:allowed_miners]
    @height = hash[:height]
    @previous_hash = hash[:previous_hash]
    @signed_by = hash[:signed_by]
    @signature = hash[:signature]
  end

  def self.from_hash(hash)
    new(hash)
  end

  # I have a feeling that real implementation
  # would need canonical block as string representation
  # but I'll keep it just as ruby's JSON to keep the project simple.
  def to_json
    {
      transactions: @transactions,
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
    @transactions_hash == TransactionsHash.new(@transactions.map(&:to_json)).calculate
  end
end
