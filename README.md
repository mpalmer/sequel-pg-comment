Databases are the ugly step-child of documentation.  Explaining what each
column and table is actually *for* suffers from the "[documentation vicious
circle](http://www.hezmatt.org/~mpalmer/blog/2015/02/15/the-documentation-vicious-circle.html)"
-- nobody writes documentation, because nobody reads it, because it never
exists, therefore there's no point even looking for it.  Unlike source code,
which allows comments to exist alongside the live-edited code, there's
typically *no way* to keep documentation at the "point of use" of an SQL
database.  Sure, you can write docs in your migrations, or a wiki somewhere,
but when you're banging away at your SQL command line, who wants to go
rummaging around in a wiki?

As with all things, PostgreSQL to the rescue!  The non-standard [`COMMENT`
command](http://www.postgresql.org/docs/current/interactive/sql-comment.html)
allows you to attach an arbitrary chunk of text to pretty much any object in
the database.  Want to document a collation?  `COMMENT ON COLLATION
<object_name> IS 'something something dark side'` and you're done!

If you're a lover of [Sequel](http://sequel.jeremyevans.net/), though, the
last thing you want to be doing is hand-writing SQL.  Blech.  That's old
school.  You want to have your comments Right There in the migrations.
That's what this gem is all about.


# Usage

First, you need to enable the plugin:

    Sequel::Database.extension :pg_comment

Then, you can attach a comment to anything you can create with [Sequel
schema
modifications](http://sequel.jeremyevans.net/rdoc/files/doc/schema_modification_rdoc.html)
by adding a `:comment` option, like so:

    create_table :comments, :comment => "Foo to you too" do
      primary_key :id, :comment => "Auto-incrementing primary key"
      String :data, :null => false, :comment => "Markdown"
      foreign_key :user_id, :users, :comment => "The user who owns the comment"

      index :user_id, :comment => "Find those user comments faster!"
    end

For some object types, though, there's no syntactic sugar in Sequel, so
you've got to create them by hand.  Never fear, though!  You can comment on
any object using Ruby code, like so:

    comment_on :collation, :my_collation, "Collate ALL THE THINGS!"

This is useful also for tables, where you might not want to insert a lengthy
comment in the top of your `create_table` block.

The `table.column` syntax that PgSQL requires for `COMMENT ON COLUMN` can be
simulated in the usual Sequel fashion, of using two underscores in the
symbol to separate the table name from the column name, like so:

    comment_on :column, :foo__bar_id, %{
      This is my column.  There are many like it, but this one is mine.
    }
    #  => COMMENT ON COLUMN "foo"."bar_id" IS 'This is my column. (etc)'

**NOTE**: The object you wish to comment on *must already exist* before you
call `comment_on`.  The following example **WILL NOT WORK**:

    comment_on :table, :foo, "This is an awesomely foo table"
    create_table :foo, do
      # ...
    end

You have to put the `comment_on` *after* the `create_table`, like this:

    create_table :foo, do
      # ...
    end
    comment_on :table, :foo, "This is an awesomely foo table"


## Comment string tidy-up

On the whole, `sequel-pg-comment` makes no judgment on what you put in your
comments.  Plain text, markdown, XML, or morse code -- it's all the same.

There is *one* manipulation that is done to multi-line comments, though, to
make it a bit easier to write lengthy treatises on the whichness of the why,
and that is to strip out leading whitespace.  The rules are very simple:

1. Empty lines at the beginning and end of the comment are removed; and

1. Whatever whitespace is present before the *first* non-empty line of the
   comment, will be stripped from the beginning of *every* line.

That means you can use a heredoc for your multi-line comments, and they'll
still look neat and tidy without having to play `gsub` tricks:

    create_table :foo do
      String :data, :comment => <<-EOF
        This is a very lengthy comment.  It goes for many lines
        and has a great deal to say on any number of subjects.  I
        could have used lorem ipsum here, but I prefer to do things
        the old-fashioned way.  If you've read all of this example,
        you probably stay to read the whole of the credits at the
        cinema.  Good for you!  I do too.  Wave next time, you
        anti-social loner.
      EOF
    end

One caveat: it's common to use the `%( ... )` quoting style for lengthy
strings.  That's fine, but make sure to put the first line of docs on its
own line, and not directly after the `%(`.  For example, this will not work
so well:

    # This WILL NOT trim leading whitespace from each line
    comment_on :table, :foo, %(This is a long comment.
      However, due to the way that pg-comment trims whitespace,
      these lines will have leading indents, because the first line
      didn't.
    )

Instead, you'll want to do this:

    # This WILL trim leading whitespace from each line
    comment_on :table, :foo, %(
      This, too, is a long comment.  Because the first non-empty
      line had leading spaces, all of these other lines will have
      their leaving spaces stripped too.
    )

As always, inconsistent use of tabs and spaces will end in disaster.  So
don't do that.  Remember: tabs are for indenting, spaces are for formatting.


## Quoting and escaping

In normal circumstances, if you follow some fairly simple rules and don't
need to put comments on a few gnarly types, you should never have to do any
SQL-specific escaping or quoting of the values you pass to the methods in
this extension.  We work very hard to properly escape as much as we can.

The rules for quoting are:

1. If an object name is passed as a symbol, it will be escaped.  For certain
   types (`COLUMN`, `CONSTRAINT`, `RULE`, and `TRIGGER`), we split on the first
   double underscore (ie `__`) and the part before the double underscore is the
   table name, and the rest is the object name.  Each part is quoted
   separately.

2. If an object name is passed as a string, **NO QUOTING IS PERFORMED**.  It
   is assumed, in that instance, that you've already done all the quoting you
   need yourself.

3. Comment strings should always be passed as strings.

4. Object types can be specified as either strings or symbols, with space-
   or understore-separated words, in any mix of case, and they will be
   correctly handled.

(Of course, the *real* rule for object naming is: *stick to alphanumerics and
underscores, fer cryin' out loud!*)

The relative complexity of these rules is due to the fact that there are a
few PostgreSQL object types which stubbornly resist attempts to
automatically escape their names in a safe manner.  The most visible
offender is `FUNCTION`, which is both relatively commonly used, and has a
*particularly* complicated object name specification.  For those types, you
have to do some quoting yourself, and pass the object name as a string.

I do apologise for the complexity and lack of *absolute* safety in all this
(although if someone can SQL inject your migrations, you're having a
*really* bad day), but I had absolutely no luck in producing an interface
that wasn't a complete nightmare to use, an implementation that wasn't a
complex mess, and that stuck fairly closely to the common idioms present in
Sequel proper.  If you happen to have ideas on how to make this better, [I'm
all ears](mailto:theshed+sequel-pg-comment@hezmatt.org).


# Getting your comments back

It's great that this gem can help you to document your database, but that's
not much use if nobody can read them again.  Within Sequel itself, you can
retrieve comments quite easily:

    DB.comment_for(:foo)  # => "Something something dark side"

For columns, you can either use the double underscore notation:

    DB.comment_for(:foo__column)  # => "Awwwwww yeah"

Or you can do the same thing from the dataset itself:

    DB[:foo].comment_for(:column)  # => "Awwwwww yeah"

There's currently no support for retrieving a database comment from a Sequel
model; pull requests implementing such a feature would be warmly welcomed.

The real value in database comments, though, comes when you  use an
entity-relationship diagram tool like
[SchemaSpy](http://schemaspy.sourceforge.net/), which draws all sorts of
pretty pictures and lays out all of the schema information.

If you quickly need to get some docs when you're in `psql`, you can get it
out of the "additional detail" informational commands, like `\dt+ <table
name>`.


# Contributing

Bug reports should be sent to the [Github issue
tracker](https://github.com/mpalmer/sequel-pg-comment/issues), or
[e-mailed](mailto:theshed+sequel-pg-comment@hezmatt.org).  Patches can be sent as a
Github pull request, or [e-mailed](mailto:theshed+sequel-pg-comment@hezmatt.org).
