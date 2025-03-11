# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Testing::Helpers do
  class AssertionsSchema < GraphQL::Schema
    use GraphQL::Schema::Warden if ADD_WARDEN
    class BillSource < GraphQL::Dataloader::Source
      def fetch(students)
        students.map { |s| { amount: 1_000_001 } }
      end
    end

    class TuitionBill < GraphQL::Schema::Object
      def self.visible?(ctx)
        ctx[:current_user]&.admin?
      end

      field :amount_in_cents, Int, hash_key: :amount
    end

    class Transcript < GraphQL::Schema::Object
      def self.authorized?(object, context)
        (current_user = context[:current_user]) &&
            (admin_for = current_user[:admin_for]) &&
            (admin_for.include?(object && object[:name]))
      end

      field :gpa, Float
    end

    class Student < GraphQL::Schema::Object
      def self.authorized?(object, context)
        context.errors.empty?
      end

      field :name, String, extras: [:ast_node] do
        argument :full_name, Boolean, required: false
        argument :prefix, String, required: false, default_value: "Mc", prepare: ->(val, ctx) { -> { val.capitalize } }
      end

      def name(full_name: nil, prefix: nil, ast_node:)
        name = object[:name]
        if full_name
          "#{name} #{ast_node.alias ? "\"#{ast_node.alias}\" " : ""}#{prefix}#{name}"
        else
          name
        end
      end

      field :latest_bill, TuitionBill

      def latest_bill
        dataloader.with(BillSource).load(object)
      end

      field :is_admin_for, Boolean
      def is_admin_for
        (list = context[:admin_for]) && list.include?(object[:name])
      end

      field :transcript, Transcript, resolver_method: :object

      class Upcase < GraphQL::Schema::FieldExtension
        def after_resolve(value:, **rest)
          value.upcase
        end
      end

      field :upcased_name, String, extensions: [Upcase], hash_key: :name

      field :ssn, String do
        def authorized?(obj, args, ctx)
          ctx[:current_user]&.admin?
        end
      end

      field :current_field, String

      def current_field
        context[:current_field].path
      end
    end

    class Query < GraphQL::Schema::Object
      field :students, [Student]

      field :student, Student do
        argument :student_id, ID, loads: Student
      end

      def student(student:)
        student
      end

      field :lookahead_selections, String, extras: [:lookahead]

      def lookahead_selections(lookahead:)
        lookahead.selections.to_s
      end
    end

    query(Query)
    use GraphQL::Dataloader
    lazy_resolve Proc, :call

    def self.unauthorized_object(err)
      raise err
    end

    def self.unauthorized_field(err)
      raise err
    end

    def self.object_from_id(id, ctx)
      if id == "s1"
        -> do { name: "Student1", type: Student } end
      else
        raise ArgumentError, "No data for id: #{id.inspect}"
      end
    end

    def self.resolve_type(abs_t, obj, ctx)
      obj.fetch(:type)
    end
  end

  include GraphQL::Testing::Helpers

  let(:admin_context) { { current_user: OpenStruct.new(admin?: true) } }

  describe "top-level helpers" do
    describe "run_graphql_field" do
      it "resolves fields" do
        assert_equal "Blah", run_graphql_field(AssertionsSchema, "Student.name", { name: "Blah" })
        assert_equal "Blah McBlah", run_graphql_field(AssertionsSchema, "Student.name", { name: "Blah" }, arguments: { "fullName" => true })
        assert_equal "Blah McBlah", run_graphql_field(AssertionsSchema, "Student.name", { name: "Blah" }, arguments: { full_name: true })
        assert_equal({ amount: 1_000_001 }, run_graphql_field(AssertionsSchema, "Student.latestBill", :student, context: admin_context))
      end

      it "loads arguments with lazy_resolve" do
        student = run_graphql_field(AssertionsSchema, "Query.student", nil, arguments: { "studentId" => "s1" })
        expected_student = { name: "Student1", type: AssertionsSchema::Student }
        assert_equal(expected_student, student)

        student2 = run_graphql_field(AssertionsSchema, "Query.student", nil, arguments: { student: "s1" })
        assert_equal(expected_student, student2)
      end

      it "works with resolution context" do
        with_resolution_context(AssertionsSchema, object: { name: "Foo" }, type: "Student", context: { admin_for: ["Foo"] }) do |rc|
          rc.run_graphql_field("name")
          rc.run_graphql_field("isAdminFor")
          assert_equal "Student.currentField", rc.run_graphql_field("currentField")
        end
      end

      it "raises an error when the type is hidden" do
        assert_equal 1_000_000, run_graphql_field(AssertionsSchema, "TuitionBill.amountInCents", { amount: 1_000_000 }, context: admin_context)

        err = assert_raises(GraphQL::Testing::Helpers::TypeNotVisibleError) do
          run_graphql_field(AssertionsSchema, "TuitionBill.amountInCents", { amount: 1_000_000 })
        end
        expected_message = "`TuitionBill` should be `visible?` this field resolution and `context`, but it was not"
        assert_equal expected_message, err.message
      end

      it "raises an error when the type isn't authorized" do
        err = assert_raises GraphQL::UnauthorizedError do
          run_graphql_field(AssertionsSchema, "Student.transcript.gpa", { gpa: 3.1 })
        end
        assert_equal "An instance of Hash failed Transcript's authorization check", err.message

        assert_equal 3.1, run_graphql_field(AssertionsSchema, "Student.transcript.gpa", { gpa: 3.1, name: "Jim" }, context: { current_user: OpenStruct.new(admin_for: ["Jim"])})
      end

      it "works with field extensions" do
        assert_equal "BILL", run_graphql_field(AssertionsSchema, "Student.upcasedName", { name: "Bill" })
      end

      it "works with extras: [:ast_node]" do
        assert_equal "Billy \"theKid\" McBilly", run_graphql_field(AssertionsSchema, "Student.name", { name: "Billy" }, arguments: { full_name: true }, ast_node: GraphQL::Language::Nodes::Field.new(name: "name", field_alias: "theKid"))
      end

      it "works with extras: [:lookahead]" do
        assert_equal "[]", run_graphql_field(AssertionsSchema, "Query.lookaheadSelections", :something)
        dummy_lookahead = OpenStruct.new(selections: ["one", "two"])
        assert_equal "[\"one\", \"two\"]", run_graphql_field(AssertionsSchema, "Query.lookaheadSelections", :something, lookahead: dummy_lookahead)
      end

      it "prepares arguments" do
        assert_equal "Blah De Blah", run_graphql_field(AssertionsSchema, "Student.name", { name: "Blah" }, arguments: { full_name: true, prefix: "de " })
      end

      it "handles unauthorized field errors" do
        assert_equal "123-45-6789", run_graphql_field(AssertionsSchema, "Student.ssn", { ssn: "123-45-6789"}, context: admin_context)
        err = assert_raises GraphQL::UnauthorizedFieldError do
          run_graphql_field(AssertionsSchema, "Student.ssn", {})
        end
        assert_equal "An instance of Hash failed AssertionsSchema::Student's authorization check on field ssn", err.message
      end

      it "raises when the type doesn't exist" do
        err = assert_raises GraphQL::Testing::Helpers::TypeNotDefinedError do
          run_graphql_field(AssertionsSchema, "Nothing.nothing", :nothing)
        end
        assert_equal "No type named `Nothing` is defined; choose another type name or define this type.", err.message
      end

      it "raises when the field doesn't exist" do
        err = assert_raises GraphQL::Testing::Helpers::FieldNotDefinedError do
          run_graphql_field(AssertionsSchema, "Student.nonsense", :student)
        end
        assert_equal "`Student` has no field named `nonsense`; pick another name or define this field.", err.message
      end
    end
  end

  describe "schema-level helpers" do
    include GraphQL::Testing::Helpers.for(AssertionsSchema)

    it "resolves fields" do
      assert_equal 5, run_graphql_field("TuitionBill.amountInCents", { amount: 5 }, context: admin_context)
    end

    it "works with resolution context" do
      with_resolution_context(object: { name: "Foo" }, type: "Student", context: { admin_for: ["Bar"] }) do |rc|
        assert_equal "Foo", rc.run_graphql_field("name")
        assert_equal false, rc.run_graphql_field("isAdminFor")
      end
    end
  end
end
