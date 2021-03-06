require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  describe "#validate_each" do

    before do
      @document = Person.new
    end

    let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes) }

    context "when a document exists with the attribute value" do

      before do
        @criteria = stub(:nil? => false)
        Person.collection.expects(:find_one).with(:title => "Sir").returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds the errors to the document" do
        @document.errors[:title].should_not be_empty
      end

      it "should translate the error in english" do
        @document.errors[:title][0].should == "is already taken"
      end
    end

    context "when a superclass document exists with the attribute value" do
      before do
        @drdocument = Doctor.new
        @criteria = stub(:nil? => false)
        Person.collection.expects(:find_one).with(:title => "Sir").returns(@criteria)
        validator.validate_each(@drdocument, :title, "Sir")
      end

      it "adds the errors to the document" do
        @drdocument.errors[:title].should_not be_empty
      end
    end

    context "when no other document exists with the attribute value" do

      before do
        @criteria = stub(:nil? => true)
        Person.collection.expects(:find_one).with(:title => "Sir").returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

      it "adds no errors" do
        @document.errors[:title].should be_empty
      end
    end

    context "when defining a single field key" do

      context "when a document exists in the db with the same key" do

        context "when the document being validated is new" do

          let(:login) do
            Login.new(:username => "chitchins")
          end

          before do
            Login.collection.expects(:find_one).with(:username => "chitchins").returns([ login ])
            validator.validate_each(login, :username, "chitchins")
          end

          it "checks the value of the key field" do
            login.errors[:username].should_not be_empty
          end
        end

        context "when the document being validated is not new" do

          context "when the id has not changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "chitchins")
              login.instance_variable_set(:@new_record, false)
              login
            end

            before do
              Login.collection.expects(:find_one).with(:username => "chitchins").returns([ login ])
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should be_empty
            end
          end

          context "when the has changed since instantiation" do

            let(:login) do
              login = Login.new(:username => "rdawkins")
              login.instance_variable_set(:@new_record, false)
              login.username = "chitchins"
              login
            end

            before do
              Login.collection.expects(:find_one).with(:username => "chitchins").returns([ login ])
              validator.validate_each(login, :username, "chitchins")
            end

            it "checks the value of the key field" do
              login.errors[:username].should_not be_empty
            end
          end
        end
      end
    end
  end

  describe "#validate_each with :scope option given" do

    before do
      @document = Person.new(:employer_id => 3, :terms => true, :title => "")
      @criteria = stub(:nil? => false)
    end

    describe "as a symbol" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes, 
                                                                      :scope => :employer_id) }

      it "should query only scoped documents" do
        Person.collection.expects(:find_one).with(:title => "Sir", 
                                    :employer_id => @document.attributes[:employer_id]).returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

    end

    describe "as an array" do

      let(:validator) { Mongoid::Validations::UniquenessValidator.new(:attributes => @document.attributes, 
                                                                      :scope => [:employer_id, :terms]) }
      it "should query only scoped documents" do
        Person.collection.expects(:find_one).with(:title => "Sir", 
                                    :employer_id => @document.attributes[:employer_id],
                                    :terms => true).returns(@criteria)
        validator.validate_each(@document, :title, "Sir")
      end

    end
  end
end
