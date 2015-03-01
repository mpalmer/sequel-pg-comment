require_relative 'spec_helper'
require 'sequel'

describe "#comment_on" do
	let(:db) do
		Sequel.connect("mock://postgres").extension(:pg_comment)
	end

	it "sets a table comment" do
		db.comment_on(:table, :foo, "Ohai!")
		expect(db.sqls).
		  to eq(["COMMENT ON TABLE \"foo\" IS 'Ohai!'"])
	end

	it "accepts a symbol as object name" do
		db.comment_on(:table, :foo, "Ohai!")
		expect(db.sqls).
		  to eq(["COMMENT ON TABLE \"foo\" IS 'Ohai!'"])
	end

	it "accepts a string as object name" do
		db.comment_on(:table, "foo", "Ohai!")
		expect(db.sqls).
		  to eq(["COMMENT ON TABLE foo IS 'Ohai!'"])
	end

	it "sets an aggregate comment" do
		db.comment_on(:aggregate, :foo, "Ohai!")
		expect(db.sqls).
		  to eq(["COMMENT ON AGGREGATE \"foo\" IS 'Ohai!'"])
	end

	it "escapes the comment" do
		db.comment_on(:table, :foo, "O'hai!")
		expect(db.sqls).
		  to eq(["COMMENT ON TABLE \"foo\" IS 'O''hai!'"])
	end

	it "explodes if an invalid object type is given" do
		expect do
			db.comment_on(:foobooblee, :foo, "O'hai!")
		end.to raise_error(Sequel::Error)
	end

	it "explodes if an invalid ID type is given for a table" do
		expect do
			db.comment_on(:table, [:foo, :bar], "Ohai!")
		end.to raise_error(Sequel::Error)
	end

	it "explodes if an invalid ID type is given for a column" do
		expect do
			db.comment_on(:column, :foo, "Ohai!")
		end.to raise_error(Sequel::Error)
	end

	it "quotes the object name" do
		db.comment_on(:table, :"foo bar", "Ohai!")
		expect(db.sqls).
		  to eq(["COMMENT ON TABLE \"foo bar\" IS 'Ohai!'"])
	end

	it "sets a column comment correctly" do
		db.comment_on(:column, [:foo, :bar_id], "Ohai, column!")
		expect(db.sqls).
		  to eq(["COMMENT ON COLUMN \"foo\".\"bar_id\" IS 'Ohai, column!'"])
	end

	it "sets a trigger comment correctly" do
		db.comment_on(:trigger, [:foo, :bar_id], "Whoa there, trigger!")
		expect(db.sqls).
		  to eq(["COMMENT ON TRIGGER \"bar_id\" ON \"foo\" IS 'Whoa there, trigger!'"])
	end
end
