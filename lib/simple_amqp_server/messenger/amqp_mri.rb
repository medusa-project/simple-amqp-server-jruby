require_relative 'base'
require 'bunny'
require 'retryable'
require 'timeout'
require 'openssl'

class SimpleAmqpServer::Messenger::AmqpMri < SimpleAmqpServer::Messenger::Base

  attr_accessor :connection, :outgoing_queue, :incoming_queue, :channel

  def initialize(logger, config)
    super
    retries = -1
    begin
      close
      connection_params = {recover_from_connection_close: true}.merge(config.amqp(:connection) || {})
      self.connection = Bunny.new(connection_params)
      self.connection.start
      self.logger.info("Connected to AMQP server")
      self.channel = connection.create_channel
      self.incoming_queue = self.channel.queue(config.amqp(:incoming_queue), durable: true)
      self.outgoing_queue = self.channel.queue(config.amqp(:outgoing_queue), durable: true) if config.amqp(:outgoing_queue)
    rescue OpenSSL::SSL::SSLError, Timeout::Error, Bunny::Exception => e
      self.logger.error("Error opening amqp connection: #{e}")
      retries = [retries + 1, 3].min
      sleep 5 ** retries
      self.logger.error("Retrying")
      retry
    end
  end

  def close
    self.logger.info("Trying to close amqp")
    self.connection.close if self.connection and self.connection.open?
    self.logger.info("Closed amqp") unless self.connection and self.connection.open?
  end

  def get_incoming_request
    Retryable.retryable(tries: 10, sleep: 60, on: [Bunny::Exception, Timeout::Error],
                        exception_cb: Proc.new {|e| self.logger.error("Error getting incoming request: #{e}")}) do
      ensure_connection
      delivery_info, properties, request = self.incoming_queue.pop
      request
    end
  end

  def send_outgoing_message(message)
    Retryable.retryable(tries: 10, sleep: 60, on: [Bunny::Exception, Timeout::Error],
                        exception_cb: Proc.new {|e| self.logger.error("Error sending outgoing message: #{e}\nMessage: #{message}")}) do
      if self.outgoing_queue
        ensure_connection
        outgoing_queue.channel.default_exchange.publish(message, routing_key: outgoing_queue.name, persistent: true)
      end
    end
  end

  private

  def ensure_connection
    self.initialize(self.logger, self.config) unless self.connection and self.connection.open?
  end

end