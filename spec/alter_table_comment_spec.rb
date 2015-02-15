require_relative 'spec_helper'
require 'sequel'

describe "schema modification" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "sets a column comment on add_column" do
		db.alter_table :foo do
			add_column(:data, String, :comment => "Owhatanight")
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"data\" IS 'Owhatanight'")
	end

	it "sets a column comment on add_primary_key" do
		db.alter_table :foo do
			add_primary_key :id, :comment => "Identify!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"id\" IS 'Identify!'")
	end

	it "sets an index comment on composite add_primary_key" do
		db.alter_table :foo do
			add_primary_key [:name, :dob], :comment => "Uniquify!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_pkey\" IS 'Uniquify!'")
	end

	it "sets a column comment on add_foreign_key" do
		db.alter_table :foo do
			add_foreign_key :bar_id, :bar, :comment => "Over there!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"bar_id\" IS 'Over there!'")
	end

	it "sets a column comment on add_foreign_key with custom constraint name" do
		db.alter_table :foo do
			add_foreign_key :bar_id, :bar, :comment => "Over there!", :name => :fkr
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"bar_id\" IS 'Over there!'")
	end

	it "sets a constraint comment on composite add_foreign_key" do
		db.alter_table :foo do
			add_foreign_key [:name, :dob], :bar, :comment => "Over there!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON CONSTRAINT \"foo_name_fkey\" ON \"foo\" IS 'Over there!'")
	end

	it "sets a constraint comment on composite add_foreign_key with custom constraint name" do
		db.alter_table :foo do
			add_foreign_key [:name, :dob], :bar, :comment => "Over there!", :name => :fkr
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON CONSTRAINT \"fkr\" ON \"foo\" IS 'Over there!'")
	end

	it "sets an index comment" do
		db.alter_table :foo do
			add_index :name, :comment => "Speedy!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_name_index\" IS 'Speedy!'")
	end

	it "sets an index comment with custom name" do
		db.alter_table :foo do
			add_index :name, :name => :some_idx, :comment => "Speedify!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"some_idx\" IS 'Speedify!'")
	end

	it "sets an index comment on multi-column index" do
		db.alter_table :foo do
			add_index [:name, :dob], :comment => "Speedizer!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_name_dob_index\" IS 'Speedizer!'")
	end

	it "sets an index comment on multi-column index with custom name" do
		db.alter_table :foo do
			add_index [:name, :dob], :name => :my_idx, :comment => "Digispeed!"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"my_idx\" IS 'Digispeed!'")
	end

	it "sets a constraint comment" do
		db.alter_table :foo do
			add_constraint(:min_length, :comment => "Bigger is better!") do
				char_length(name) > 2
			end
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON CONSTRAINT \"min_length\" ON \"foo\" IS 'Bigger is better!'")
	end

	it "sets a unique constraint comment" do
		db.alter_table :foo do
			add_unique_constraint [:name, :dob], :comment => "Only one"
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_name_dob_key\" IS 'Only one'")
	end

	it "sets a unique constraint comment with custom name" do
		db.alter_table :foo do
			add_unique_constraint [:name, :dob],
			                      :comment => "Only one",
			                      :name => :uniquify
		end
		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"uniquify\" IS 'Only one'")
	end
end
