module AfterCommit
  module ConnectionAdapters
    def self.included(base)
      base.class_eval do
        def transaction_with_callback(*args, &block)
          # @disable_rollback is set to false at the start of the
          # outermost call to #transaction.  After committing, it is
          # set to true to prevent exceptions causing a spurious
          # rollback.
          outermost_call = @disable_rollback.nil?
          @disable_rollback = false if outermost_call
          transaction_without_callback(*args, &block)
        ensure
          @disable_rollback = nil if outermost_call
        end
        alias_method_chain :transaction, :callback

        # The commit_db_transaction method gets called when the outermost
        # transaction finishes and everything inside commits. We want to
        # override it so that after this happens, any records that were saved
        # or destroyed within this transaction now get their after_commit
        # callback fired.
        def commit_db_transaction_with_callback
          increment_transaction_pointer
          begin
            result = nil
            trigger_before_commit_callbacks
            trigger_before_commit_on_create_callbacks
            trigger_before_commit_on_update_callbacks
            trigger_before_commit_on_save_callbacks
            trigger_before_commit_on_destroy_callbacks

            result = commit_db_transaction_without_callback
            @disable_rollback = true

            trigger_after_commit_callbacks
            trigger_after_commit_on_create_callbacks
            trigger_after_commit_on_update_callbacks
            trigger_after_commit_on_save_callbacks
            trigger_after_commit_on_destroy_callbacks
            trigger_after_commit_class_callbacks
            result
          ensure
            AfterCommit.cleanup(self)
            decrement_transaction_pointer
          end
        end
        alias_method_chain :commit_db_transaction, :callback

        # In the event the transaction fails and rolls back, nothing inside
        # should recieve the after_commit callback, but do fire the after_rollback
        # callback for each record that failed to be committed.
        def rollback_db_transaction_with_callback
          if @disable_rollback
            # if rollback is called and @disable_rollback is true, then ActiveRecord is trying to
            # rollback from an exception in an `after_commit` block. Only rollback once by checking
            # to see if we are back at the top level `after_commit` transaction
           rollback_db_transaction_without_callback if transaction_pointer == 0
           return
          end
          increment_transaction_pointer
          begin
            result = nil
            trigger_before_rollback_callbacks
            result = rollback_db_transaction_without_callback
            trigger_after_rollback_callbacks
            trigger_after_rollback_class_callbacks
            result
          ensure
            AfterCommit.cleanup(self)
            decrement_transaction_pointer
          end
        end
        alias_method_chain :rollback_db_transaction, :callback

        def unique_transaction_key
          [object_id, transaction_pointer]
        end

        def old_transaction_key
          [object_id, transaction_pointer - 1]
        end

        protected

        def trigger_after_commit_class_callbacks
          AfterCommit.classes_records(self).each do |record|
            record.send :callback, :after_class_commit
          end
        end

        def trigger_after_rollback_class_callbacks
          AfterCommit.classes_records(self).each do |record|
            record.send :callback, :after_class_rollback
          end
        end

        def trigger_before_commit_callbacks
          AfterCommit.records(self).each do |record|
            record.send :callback, :before_commit
          end
        end

        def trigger_before_commit_on_create_callbacks
          AfterCommit.created_records(self).each do |record|
            record.send :callback, :before_commit_on_create
          end
        end

        def trigger_before_commit_on_update_callbacks
          AfterCommit.updated_records(self).each do |record|
            record.send :callback, :before_commit_on_update
          end
        end

        def trigger_before_commit_on_save_callbacks
          AfterCommit.saved_records(self).each do |record|
            record.send :callback, :before_commit_on_save
          end
        end

        def trigger_before_commit_on_destroy_callbacks
          AfterCommit.destroyed_records(self).each do |record|
            record.send :callback, :before_commit_on_destroy
          end
        end

        def trigger_before_rollback_callbacks
          AfterCommit.records(self).each do |record|
            record.send :callback, :before_rollback
          end
        end

        def trigger_after_commit_callbacks
          # Trigger the after_commit callback for each of the committed
          # records.
          AfterCommit.records(self).each do |record|
            record.send :callback, :after_commit
          end
        end

        def trigger_after_commit_on_create_callbacks
          # Trigger the after_commit_on_create callback for each of the committed
          # records.
          AfterCommit.created_records(self).each do |record|
            record.send :callback, :after_commit_on_create
          end
        end

        def trigger_after_commit_on_update_callbacks
          # Trigger the after_commit_on_update callback for each of the committed
          # records.
          AfterCommit.updated_records(self).each do |record|
            record.send :callback, :after_commit_on_update
          end
        end

        def trigger_after_commit_on_save_callbacks
          # Trigger the after_commit_on_save callback for each of the committed
          # records.
          AfterCommit.saved_records(self).each do |record|
            record.send :callback, :after_commit_on_save
          end
        end

        def trigger_after_commit_on_destroy_callbacks
          # Trigger the after_commit_on_destroy callback for each of the committed
          # records.
          AfterCommit.destroyed_records(self).each do |record|
            record.send :callback, :after_commit_on_destroy
          end
        end

        def trigger_after_rollback_callbacks
          # Trigger the after_rollback callback for each of the committed
          # records.
          AfterCommit.records(self).each do |record|
            record.send :callback, :after_rollback
          end
        end

        def transaction_pointer
          Thread.current[:after_commit_pointer] ||= 0
        end

        def increment_transaction_pointer
          Thread.current[:after_commit_pointer] ||= 0
          Thread.current[:after_commit_pointer] += 1
        end

        def decrement_transaction_pointer
          Thread.current[:after_commit_pointer] ||= 0
          Thread.current[:after_commit_pointer] -= 1
        end

      end
    end
  end
end
