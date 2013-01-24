module FourColumnMapping
  class Format < GoCart::Format
    def initialize
      super
      create_table :header, :headers => true, :name => "Sample" do |t|
        t.string :a, :header => "A", :index => 1, :description => "A column."
        t.string :b, :header => "B", :index => 2, :description => "B column."
        t.integer :c, :header => "C", :index => 3, :description => "C column."
        t.integer :d, :header => "D", :index => 4, :description => "D column."
      end
      create_table :no_header, :headers => false, :name => "Sample" do |t|
        t.string :a, :index => 1, :description => "A column."
        t.string :b, :index => 2, :description => "B column."
        t.integer :c, :index => 3, :description => "C column."
        t.integer :d, :index => 4, :description => "D column."
      end
    end
  end

  class Schema < GoCart::Schema
    def initialize
      super
      create_table :sample do |t|
        t.string :a
        t.string :b
        t.integer :c
        t.integer :d
      end
    end
  end

  class Mapper < GoCart::Mapper

    attr_accessor :format, :schema

    def initialize
      super(Format.new, Schema.new)
      create_mapping :sample, to => schema.sample, from => format_table.sample do |m|
        m.map :a, :a
        m.map :b, :b
        m.map :c, :c
        m.map :d, :d
      end
    end
  end
end