require_relative 'spec_helper'

require 'sequel'
require 'sequel/extensions/pg_comment'

describe "SqlGenerator" do
	SqlGenerator = Sequel::Postgres::Comment::SqlGenerator
	PrefixSqlGenerator = Sequel::Postgres::Comment::PrefixSqlGenerator

	context "a simple type expressed as a string" do
		let(:generator) { SqlGenerator.create("TABLE", :foo, "Ohai!") }

		it "generates quoted SQL" do
			expect(generator.generate).
			  to eq("COMMENT ON TABLE \"foo\" IS 'Ohai!'")
		end
	end

	context "a simple type expressed as a crazy-case string" do
		let(:generator) { SqlGenerator.create("TaBlE", :foo, "Ohai!") }

		it "generates quoted SQL" do
			expect(generator.generate).
			  to eq("COMMENT ON TABLE \"foo\" IS 'Ohai!'")
		end
	end

	context "a simple type expressed as a symbol" do
		let(:generator) { SqlGenerator.create(:table, :foo, "Ohai!") }

		it "generates quoted SQL" do
			expect(generator.generate).
			  to eq("COMMENT ON TABLE \"foo\" IS 'Ohai!'")
		end
	end

	context "a multi-word type expressed as a symbol" do
		let(:generator) { SqlGenerator.create(:event_trigger, :foo, "Ohai!") }

		it "generates correct SQL" do
			expect(generator.generate).
			  to eq("COMMENT ON EVENT TRIGGER \"foo\" IS 'Ohai!'")
		end
	end

	context "with a string as the object name" do
		let(:generator) { SqlGenerator.create(:table, "foo", "Ohai!") }

		it "generates unquoted SQL" do
			expect(generator.generate).
			  to eq("COMMENT ON TABLE foo IS 'Ohai!'")
		end
	end
		
	it "escapes the comment" do
		expect(SqlGenerator.create(:table, :foo, "O'hai!").generate).
		  to eq("COMMENT ON TABLE \"foo\" IS 'O''hai!'")
	end

	it "explodes if an invalid object type is given" do
		expect do
			SqlGenerator.create(:foobooblee, :foo, "O'hai!")
		end.to raise_error(ArgumentError, /unrecognised object type/i)
	end

	it "sets a column comment correctly" do
		expect(SqlGenerator.create(:column, :foo__bar_id, "Ohai, column!").generate).
		  to eq("COMMENT ON COLUMN \"foo\".\"bar_id\" IS 'Ohai, column!'")
	end

	it "sets a constraint comment correctly" do
		g = SqlGenerator.create(:constraint, :foo__not_for_you, "Ohai, constraint!")
		expect(g.generate).
		  to eq("COMMENT ON CONSTRAINT \"not_for_you\" ON \"foo\" IS 'Ohai, constraint!'")
	end

	it "sets a rule comment correctly" do
		g = SqlGenerator.create(:rule, :foo__not_for_you, "Ohai, rule!")
		expect(g.generate).
		  to eq("COMMENT ON RULE \"not_for_you\" ON \"foo\" IS 'Ohai, rule!'")
	end

	it "sets a trigger comment correctly" do
		g = SqlGenerator.create(:trigger, :foo__spoing, "Ohai, trigger!")
		expect(g.generate).
		  to eq("COMMENT ON TRIGGER \"spoing\" ON \"foo\" IS 'Ohai, trigger!'")
	end

	it "sets a comment on a prefixed name correctly" do
		g = PrefixSqlGenerator.new(:index, :_pkey, "Ohai, pkey!")
		g.table_name = :foo

		expect(g.generate).
		  to eq("COMMENT ON INDEX \"foo_pkey\" IS 'Ohai, pkey!'")
	end
end
