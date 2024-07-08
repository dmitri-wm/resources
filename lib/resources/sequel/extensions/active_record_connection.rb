# frozen_string_literal: true

# Sequel is a database toolkit for Ruby
require_relative 'active_record_connection/utils'

module Sequel
  # ActiveRecordConnection module provides integration between Sequel and ActiveRecord
  module ActiveRecordConnection
    Error = Class.new(Sequel::Error)

    TRANSACTION_ISOLATION_MAP = {
      uncommitted: :read_uncommitted,
      committed: :read_committed,
      repeatable: :repeatable_read,
      serializable: :serializable
    }.freeze

    def self.extended(db)
      db.active_record_model = ActiveRecord::Base
      db.opts[:test] = false unless db.opts.key?(:test)

      begin
        require_relative "active_record_connection/#{db.adapter_scheme}"
        db.extend Sequel::ActiveRecordConnection.const_get(db.adapter_scheme.capitalize)
      rescue LoadError => e
        puts e.message
        puts e.backtrace
        # assume the Sequel adapter already works with Active Record
      end
    end

    attr_accessor :active_record_model

    # Ensure Sequel is not creating its own connection anywhere.
    def connect(*)
      raise Error, "creating a Sequel connection is not allowed"
    end

    def extension(*)
      super
    rescue ActiveRecord::NoDatabaseError
      warn "Sequel database extension #{@loaded_extensions.last.inspect} failed to initialize because there is no database."
    end

    # Avoid calling Sequel's connection pool, instead use Active Record's.
    def synchronize(*)
      active_record_lock do
        conn = active_record_connection.raw_connection

        if active_record_connection_class && !conn.is_a?(active_record_connection_class)
          raise Error,
                "expected Active Record connection to be a #{active_record_connection_class}, got #{conn.class}"
        end

        yield conn
      end
    ensure
      clear_active_record_query_cache
    end

    # Log executed queries into Active Record logger as well.
    def log_connection_yield(sql, conn, args = nil)
      sql += "; #{args.inspect}" if args

      active_record_log(sql) { super }
    end

    # Match database timezone with Active Record.
    def timezone
      @timezone || active_record_timezone
    end

    private

    # Synchronizes transaction state with ActiveRecord. Sequel uses this
    # information to know whether we're in a transaction, whether to create a
    # savepoint, when to run transaction/savepoint hooks etc.
    def _trans(conn)
      hash = super || { savepoints: [], active_record: true }

      # add any ActiveRecord transactions/savepoints that have been opened
      # directly via ActiveRecord::Base.transaction
      while hash[:savepoints].length < active_record_connection.open_transactions
        hash[:savepoints] << { active_record: true }
      end

      # remove any ActiveRecord transactions/savepoints that have been closed
      # directly via ActiveRecord::Base.transaction
      while hash[:savepoints].length > active_record_connection.open_transactions && hash[:savepoints].last[:active_record]
        hash[:savepoints].pop
      end

      # sync knowledge about joinability of current ActiveRecord transaction/savepoint
      if active_record_connection.transaction_open? && !active_record_connection.current_transaction.joinable?
        hash[:savepoints].last[:auto_savepoint] = true
      end

      if hash[:savepoints].empty? && hash[:active_record]
        Sequel.synchronize { @transactions.delete(conn) }
      else
        Sequel.synchronize { @transactions[conn] = hash }
      end

      super
    end

    def begin_transaction(_conn, opts = OPTS)
      isolation = TRANSACTION_ISOLATION_MAP.fetch(opts[:isolation]) if opts[:isolation]
      joinable  = !opts[:auto_savepoint]

      active_record_connection.begin_transaction(isolation: isolation, joinable: joinable)
    end

    def commit_transaction(_conn, _opts = OPTS)
      active_record_connection.commit_transaction
    end

    def rollback_transaction(_conn, _opts = OPTS)
      active_record_connection.rollback_transaction
    end

    # When Active Record holds the transaction, we cannot use Sequel hooks,
    # because Sequel doesn't have knowledge of when the transaction is
    # committed. So in this case we register an Active Record hook using the
    # after_commit_everywhere gem.
    def add_transaction_hook(conn, type, block)
      if _trans(conn)[:active_record]
        active_record_transaction_callback(type, &block)
      else
        super
      end
    end

    # When Active Record holds the savepoint, we cannot use Sequel hooks,
    # because Sequel doesn't have knowledge of when the savepoint is
    # released. So in this case we register an Active Record hook using the
    # after_commit_everywhere gem.
    def add_savepoint_hook(conn, type, block)
      if _trans(conn)[:savepoints].last[:active_record]
        active_record_transaction_callback(type, &block)
      else
        super
      end
    end

    if ActiveRecord.version >= Gem::Version.new("7.2.0.alpha")
      def active_record_transaction_callback(type, &block)
        active_record_connection.current_transaction.public_send(type, &block)
      end
    else
      require_relative "after_commit_everywhere"

      def active_record_transaction_callback(type, &block)
        AfterCommitEverywhere.public_send(type, &block)
      end
    end

    # Prevents sql_log_normalizer DB extension from skipping the normalization.
    def skip_logging?
      return false if @loaded_extensions.include?(:sql_log_normalizer)

      super
    end

    if ActiveRecord.version >= Gem::Version.new("7.0")
      def clear_active_record_query_cache
        active_record_model.clear_query_caches_for_current_thread
      end
    else
      def clear_active_record_query_cache
        active_record_connection.clear_query_cache
      end
    end

    # Active Record doesn't guarantee that a single connection can only be used
    # by one thread at a time, so we need to use locking, which is what Active
    # Record does internally as well.
    if ActiveRecord.version >= Gem::Version.new("5.1.0")
      def active_record_lock(&block)
        active_record_connection.lock.synchronize do
          ActiveSupport::Dependencies.interlock.permit_concurrent_loads(&block)
        end
      end
    else
      def active_record_lock
        yield
      end
    end

    def active_record_connection
      active_record_model.connection
    end

    def active_record_connection_class
      # defines in adapter modules
    end

    def active_record_log(sql, &block)
      ActiveSupport::Notifications.instrument(
        "sql.active_record",
        sql: sql,
        name: "Sequel",
        connection: active_record_connection,
        &block
      )
    end

    if ActiveRecord.version >= Gem::Version.new("7.0")
      def active_record_timezone
        ActiveRecord.default_timezone
      end
    else
      def active_record_timezone
        ActiveRecord::Base.default_timezone
      end
    end
  end

  Database.register_extension(:active_record_connection, ActiveRecordConnection)
end
