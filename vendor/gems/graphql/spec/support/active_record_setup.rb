# frozen_string_literal: true
if testing_rails?
  # Remove the old sqlite database
  sqlite_path = File.expand_path(File.join(__FILE__, "../../../_test_.db"))
  puts "Removing #{sqlite_path}"
  `rm -f #{sqlite_path}`

  if ActiveRecord.respond_to?(:async_query_executor=) # Rails 7.1+
    ActiveRecord.async_query_executor ||= :global_thread_pool
  end

  if ENV['DATABASE'] == 'POSTGRESQL'
    ar_connection_options = {
      host: "localhost",
      adapter: "postgresql",
      username: "postgres",
      password: ENV["PGPASSWORD"], # empty in development, populated for GH Actions
      database: "graphql_ruby_test",
    }
    ActiveRecord::Base.establish_connection(ar_connection_options.merge(
      database: "postgres"
    ))
    databases = ActiveRecord::Base.connection.execute("select datname from pg_database;")
    test_db = databases.find { |d| d["datname"] == "graphql_ruby_test" }
    if test_db.nil?
      ActiveRecord::Base.connection.execute("create database graphql_ruby_test;")
    end

    ActiveRecord::Base.configurations = {
      starwars: ar_connection_options,
      starwars_replica: ar_connection_options,
    }

    SequelDB = Sequel.connect("postgres://postgres:#{ENV["PGPASSWORD"]}@localhost:5432/graphql_ruby_test")
  else
    ActiveRecord::Base.configurations = {
      starwars: { adapter: "sqlite3", database: sqlite_path },
      starwars_replica: { adapter: "sqlite3", database: sqlite_path },
    }
    SequelDB = Sequel.sqlite(sqlite_path)
  end

  ActiveRecord::Base.establish_connection(:starwars)
  ActiveRecord::Schema.define do
    self.verbose = !!ENV["GITHUB_ACTIONS"]
    create_table :bases, force: true do |t|
      t.column :name, :string
      t.column :planet, :string
      t.column :faction_id, :integer
    end

    create_table :foods, force: true do |t|
      t.column :name, :string
    end

    create_table :things, force: true do |t|
      t.string :name
      t.integer :other_thing_id
    end

    create_table :bands, force: true do |t|
      t.string :name
      t.integer :genre
      t.integer :thing_id
      t.string :thing_type
    end

    create_table :albums, force: true do |t|
      t.string :name
      t.integer :band_id
    end

    create_table :books do |t|
      t.string :title
      t.integer :author_id
    end

    create_table :reviews do |t|
      t.integer :stars
      t.integer :user_id
      t.integer :book_id
    end

    create_table :authors do |t|
      t.string :name
    end

    create_table :users do |t|
      t.string :username
    end

    create_table :input_test_users, force: true do |t|
      t.datetime :created_at
      t.date :birthday
      t.integer :points
      t.decimal :rating
      t.references :friend, foreign_key: { to_table: :input_test_users}
    end

    create_table :test_users, force: true do |t|
      t.datetime :created_at
      t.date :birthday
      t.integer :points, null: false
      t.decimal :rating, null: false
    end
  end

  class Food < ActiveRecord::Base
    include GlobalID::Identification
  end

  class Album < ActiveRecord::Base
    belongs_to :band
  end
  class Band < ActiveRecord::Base
    has_many :albums
    enum :genre, [:rock, :country, :jazz]
    belongs_to :thing, polymorphic: true
  end

  class AlternativeBand < Band
    self.table_name = :bands
    self.primary_key = :name
  end

  v = Band.create!(id: 1, name: "Vulfpeck", genre: :rock)
  t = Band.create!(id: 2, name: "Tom's Story", genre: :rock, thing: v)
  c = Band.create!(id: 3, name: "Chon", genre: :rock, thing: v)
  w = Band.create!(id: 4, name: "Wilco", genre: :country, thing: v)

  v.albums.create!(id: 1, name: "Mit Peck")
  v.albums.create!(id: 2, name: "My First Car")
  t.albums.create!(id: 3, name: "Tom's Story")
  c.albums.create!(id: 4, name: "Homey")
  c.albums.create!(id: 5, name: "Chon")
  w.albums.create!(id: 6, name: "Summerteeth")
  class Author < ActiveRecord::Base
    has_many :books
  end

  class User < ActiveRecord::Base
    has_many :reviews
  end

  class Book < ActiveRecord::Base
    has_many :reviews
    belongs_to :author
  end

  class Review < ActiveRecord::Base
    belongs_to :user
    belongs_to :book
  end

  data = [
    {
      author: "William Shakespeare",
      titles: [
        "A Midsummer Night's Dream",
        "The Merry Wives of Windsor",
        "Much Ado about Nothing",
        "Julius Caesar",
        "Hamlet",
        "King Lear",
        "Macbeth",
        "Romeo and Juliet",
        "Othello"
      ]
    },
    {
      author: "Beatrix Potter",
      titles: [
        "The Tale of Peter Rabbit",
        "The Tale of Squirrel Nutkin",
        "The Tailor of Gloucester",
        "The Tale of Benjamin Bunny",
        "The Tale of Two Bad Mice",
        "The Tale of Mrs. Tiggy-Winkle",
        "The Tale of The Pie and the Patty-Pan",
        "The Tale of Mr. Jeremy Fisher",
        "The Story of a Fierce Bad Rabbit",
      ]
    },
    {
      author: "Charles Dickens",
      titles: [
        "The Pickwick Papers",
        "Oliver Twist",
        "A Christmas Carol",
        "David Copperfield",
        "Little Dorrit 	",
        "A Tale of Two Cities",
        "Great Expectations",
      ]
    }
  ]

  data.each do |info|
    author = Author.create!(name: info[:author])
    info[:titles].each do |title|
      Book.create!(author: author, title: title)
    end
  end

  users = ["matz", "tenderlove", "dhh", "_why"].map { |un| User.create!(username: un) }

  possible_stars = [1,2,3,4,5]
  Book.all.each do |book|
    users.each_with_index do |user, idx|
      Review.create!(book: book, user: user, stars: possible_stars[idx])
    end
  end
end
