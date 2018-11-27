module AfterCommit
  def self.add_class_to_after_commit_stack(klass)
    add_to_class_collection(::ActiveRecord::Base.connection, klass.new)
  end

  def self.record(connection, record)
    add_to_collection(:committed_records, connection, record)
    add_to_class_collection(connection, record)
  end

  def self.record_created(connection, record)
    add_to_collection  :committed_records_on_create, connection, record
  end

  def self.record_updated(connection, record)
    add_to_collection  :committed_records_on_update, connection, record
  end

  def self.record_saved(connection, record)
    add_to_collection  :committed_records_on_save, connection, record
  end

  def self.record_destroyed(connection, record)
    add_to_collection  :committed_records_on_destroy, connection, record
  end

  def self.records(connection)
    collection :committed_records, connection
  end

  def self.created_records(connection)
    collection :committed_records_on_create, connection
  end

  def self.updated_records(connection)
    collection :committed_records_on_update, connection
  end

  def self.saved_records(connection)
    collection :committed_records_on_save, connection
  end

  def self.destroyed_records(connection)
    collection :committed_records_on_destroy, connection
  end

  def self.classes_records(connection)
    collection :committed_classes_records, connection
  end

  def self.cleanup(connection)
    %i[
      committed_records
      committed_records_on_create
      committed_records_on_update
      committed_records_on_save
      committed_records_on_destroy
      committed_classes_records
    ].each do |collection|
      Thread.current[collection] &&
        Thread.current[collection].delete(connection.old_transaction_key)
    end
    Thread.current[:committed_classes] &&
      Thread.current[:committed_classes].delete(connection.old_transaction_key)
  end

  def self.add_to_class_collection(connection, record)
    committed_classes = collection_map(:committed_classes)
    transaction_key = connection.unique_transaction_key

    classes = committed_classes[transaction_key]
    if classes
      return unless classes.add?(record.class)
    else
      committed_classes[transaction_key] = Set.new([record.class])
    end
    add_to_collection(:committed_classes_records, connection, record)
  end

  def self.add_to_collection(collection, connection, record)
    collection_map = collection_map(collection)
    transaction_key = connection.unique_transaction_key

    records = collection_map[transaction_key]
    if records
      records << record
    else
      collection_map[transaction_key] = [record]
    end
  end

  def self.collection(collection, connection)
    collection_map(collection)[connection.old_transaction_key] ||= []
  end

  def self.collection_map(collection)
    Thread.current[collection] ||= {}
    Thread.current[collection]
  end
end

require 'after_commit/active_support_callbacks'
require 'after_commit/active_record'
require 'after_commit/connection_adapters'
require 'after_commit/after_savepoint'

ActiveRecord::Base.send(:include, AfterCommit::ActiveRecord)
ActiveRecord::Base.include_after_commit_extensions
