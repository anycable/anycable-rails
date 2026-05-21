# frozen_string_literal: true

class CreateAnycablePostgresSignalling < ActiveRecord::Migration<%= migration_version %>
  def up
    execute <<~SQL
      CREATE TABLE anycable_contracts (
        name text PRIMARY KEY,
        version integer NOT NULL,
        created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      INSERT INTO anycable_contracts (name, version)
      VALUES ('postgres_signalling', 1)
      ON CONFLICT (name) DO UPDATE SET version = EXCLUDED.version;

      -- App processes insert the exact AnyCable JSON envelope here. The payload
      -- stays as text so large messages are not constrained by PostgreSQL's
      -- NOTIFY payload limit and JSON is not normalized by jsonb conversion.
      CREATE TABLE anycable_broadcasts (
        id bigserial PRIMARY KEY,
        payload text NOT NULL,
        claimed_by text,
        claimed_at timestamp with time zone,
        attempts integer NOT NULL DEFAULT 0,
        last_error text,
        created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX index_anycable_broadcasts_claimed_at_id
        ON anycable_broadcasts (claimed_at, id)
        WHERE claimed_at IS NOT NULL;

      CREATE INDEX index_anycable_broadcasts_attempts_id
        ON anycable_broadcasts (attempts, id);

      -- anycable-go uses this table for multi-node fan-out. Each node keeps its
      -- own in-memory cursor for subscribed streams and polls by (stream, id).
      CREATE TABLE anycable_pubsub (
        id bigserial PRIMARY KEY,
        stream text NOT NULL,
        payload text NOT NULL,
        created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX index_anycable_pubsub_stream_id
        ON anycable_pubsub (stream, id);

      CREATE INDEX index_anycable_pubsub_created_at
        ON anycable_pubsub (created_at);

      -- The notification is intentionally tiny. It only wakes listeners; the
      -- payload is always fetched from the backing table.
      CREATE FUNCTION anycable_notify_signal()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        PERFORM pg_notify(
          'anycable_signals',
          json_build_object('v', 1, 'table', TG_TABLE_NAME, 'id', NEW.id)::text
        );
        RETURN NEW;
      END;
      $$;

      CREATE TRIGGER anycable_broadcasts_notify_insert
      AFTER INSERT ON anycable_broadcasts
      FOR EACH ROW EXECUTE FUNCTION anycable_notify_signal();

      CREATE TRIGGER anycable_pubsub_notify_insert
      AFTER INSERT ON anycable_pubsub
      FOR EACH ROW EXECUTE FUNCTION anycable_notify_signal();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS anycable_broadcasts_notify_insert ON anycable_broadcasts;
      DROP TRIGGER IF EXISTS anycable_pubsub_notify_insert ON anycable_pubsub;
      DROP FUNCTION IF EXISTS anycable_notify_signal();
      DROP TABLE IF EXISTS anycable_pubsub;
      DROP TABLE IF EXISTS anycable_broadcasts;
      DROP TABLE IF EXISTS anycable_contracts;
    SQL
  end
end
