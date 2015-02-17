require_relative 'spec_helper'
require 'sequel'

describe "schema creation" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "sets a table comment" do
		db.create_table(:foo, :comment => "Ohai!") do
			String :data
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON TABLE \"foo\" IS 'Ohai!'")
	end

	it "sets a column comment" do
		db.create_table :foo do
			String :data, :comment => "Owhatanight"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"data\" IS 'Owhatanight'")
	end

	it "sets a table comment on :as query" do
		db.create_table(
		  :older_items,
		  :as => db[:items].where { updated_at < Date.today << 6 },
		  :comment => "WTF?"
		)
		expect(db.sqls.last).
		  to eq("COMMENT ON TABLE \"older_items\" IS 'WTF?'")
	end

	it "sets a primary key comment" do
		db.create_table :foo do
			primary_key :id, :comment => "I am unique"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"id\" IS 'I am unique'")
	end

	it "sets a primary key comment on a custom constraint name" do
		db.create_table :foo do
			primary_key :id,
			            :comment => "I am unique",
			            :name => :custom_pk
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"id\" IS 'I am unique'")
	end

	it "sets a composite primary key comment" do
		db.create_table :foo do
			primary_key [:bar, :baz],
			            :comment => "So many things"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_pkey\" IS 'So many things'")
	end

	it "sets a composite primary key comment with custom constraint name" do
		db.create_table :foo do
			primary_key [:bar, :baz],
			            :comment => "So many things",
			            :name => :custom_pk
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"custom_pk\" IS 'So many things'")
	end

	it "sets a foreign_key comment" do
		db.create_table :foo do
			foreign_key :bar_id, :bar, :comment => "Over there!"
		end
		
		expect(db.sqls.last).
		  to eq("COMMENT ON COLUMN \"foo\".\"bar_id\" IS 'Over there!'")
	end

	it "sets a composite foreign_key comment" do
		db.create_table :foo do
			foreign_key [:bar_name, :bar_dob], :bar, :comment => "Over there!"
		end
		
		expect(db.sqls.last).
		  to eq("COMMENT ON CONSTRAINT \"bar_bar_name_fkey\" ON \"foo\" IS 'Over there!'")
	end

	it "sets a composite foreign_key comment with custom name" do
		db.create_table :foo do
			foreign_key [:bar_name, :bar_dob],
			            :bar,
			            :comment => "Over there!",
			            :name    => :fkr
		end
		
		expect(db.sqls.last).
		  to eq("COMMENT ON CONSTRAINT \"fkr\" ON \"foo\" IS 'Over there!'")
	end

	it "sets an index comment" do
		db.create_table :foo do
			Integer :id
			index :id, :comment => "Makes it fast"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_id_index\" IS 'Makes it fast'")
	end

	it "sets an index comment on multiple columns" do
		db.create_table :foo do
			Integer :id
			index [:name, :dob], :comment => "Makes it fast"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_name_dob_index\" IS 'Makes it fast'")
	end

	it "sets an index comment with custom index name" do
		db.create_table :foo do
			Integer :id
			index :id, :comment => "Makes it fast", :name => :zoom
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"zoom\" IS 'Makes it fast'")
	end

	it "sets a unique index comment" do
		db.create_table :foo do
			Integer :id
			unique :id, :comment => "There can be only one"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_id_key\" IS 'There can be only one'")
	end

	it "sets a unique index comment on multiple columns" do
		db.create_table :foo do
			String :name
			Date   :dob
			unique [:name, :dob], :comment => "Going solo"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"foo_name_dob_key\" IS 'Going solo'")
	end

	it "sets a unique index comment with custom name" do
		db.create_table :foo do
			Integer :id
			unique :id, :comment => "Going solo", :name => :zoom
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON INDEX \"zoom\" IS 'Going solo'")
	end

	it "sets a constraint comment" do
		db.create_table :foo do
			constraint :clamp, :num => 1..5, :comment => "Toight"
		end

		expect(db.sqls.last).
		  to eq("COMMENT ON CONSTRAINT \"clamp\" ON \"foo\" IS 'Toight'")
	end

	it "blows up trying to an unnamed constraint comment" do
		expect do
			db.create_table :foo do
				constraint nil, :num => 1..5, :comment => "Kaboom"
			end
		end.to raise_error(Sequel::Error, /not supported/i)
	end

	it "blows up trying to comment on a check" do
		expect do
			db.create_table :foo do
				check(:comment => "Kaboom") { char_length(name) > 2 }
			end
		end.to raise_error(Sequel::Error, /not supported/i)
	end
end
