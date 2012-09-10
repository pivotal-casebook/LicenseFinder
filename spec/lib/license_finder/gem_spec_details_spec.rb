require 'spec_helper'

describe LicenseFinder::GemSpecDetails do
  before do
    @mock_gemspec = Class.new do
      def initialize(path = nil)
        @path = path
      end

      def name
        'spec_name'
      end

      def version
        '2.1.3'
      end

      def full_gem_path
        if @path
          gem_install_path = File.join(File.dirname(__FILE__), '..', '..', '..', @path)
          raise Errno::ENOENT, @path unless File.exists?(gem_install_path)
          gem_install_path
        else
          'install/path'
        end
      end

      def license
        nil
      end
    end
  end

  subject { LicenseFinder::GemSpecDetails.new(@mock_gemspec.new) }

  its(:name) { should == 'spec_name 2.1.3' }
  its(:dependency_name) { should == 'spec_name' }
  its(:dependency_version) { should == '2.1.3' }
  its(:install_path) { should == 'install/path' }

  describe "#determine_license" do
    it "returns the license from the gemspec if provided" do
      mock_gemspec = @mock_gemspec.new
      stub(mock_gemspec).license { "MIT" }
      LicenseFinder::GemSpecDetails.new(mock_gemspec).determine_license.should == "MIT"
    end

    it "returns the matched license if detected" do
      mock_gemspec = @mock_gemspec.new
      mock_license_file = LicenseFinder::LicenseFile.new('gem', 'gem/license/path')
      stub(mock_license_file).license { LicenseFinder::License::Ruby }

      gemspec_details = LicenseFinder::GemSpecDetails.new(mock_gemspec)
      stub(gemspec_details).license_files { [ mock_license_file ] }

      gemspec_details.determine_license.should == "ruby"
    end

    it "returns 'other' otherwise" do
      mock_gemspec = @mock_gemspec.new
      mock_license_file = LicenseFinder::LicenseFile.new('gem', 'gem/license/path')
      stub(mock_license_file).license { nil }

      gemspec_details = LicenseFinder::GemSpecDetails.new(mock_gemspec)
      stub(gemspec_details).license_files { [ mock_license_file ] }

      gemspec_details.determine_license.should == "other"
    end
  end

  describe "#license_files" do
    it "is empty if there aren't any license files" do
      LicenseFinder::GemSpecDetails.new(@mock_gemspec.new).license_files.should == []
    end

    it "includes files with names like LICENSE, License or COPYING" do
      gem_spec = @mock_gemspec.new('spec/fixtures/license_names')
      LicenseFinder::GemSpecDetails.new(gem_spec).license_files.map(&:file_name).should =~
          %w[COPYING.txt LICENSE Mit-License README.rdoc]
    end

    it "includes files deep in the hierarchy" do
      gem_spec = @mock_gemspec.new('spec/fixtures/nested_gem')
      LicenseFinder::GemSpecDetails.new(gem_spec).license_files.map { |f| [f.file_name, f.file_path] }.should =~
          [['LICENSE', 'vendor/LICENSE']]
    end

    it "includes both files nested inside LICENSE directory and top level files" do
      gem_spec = @mock_gemspec.new('spec/fixtures/license_directory')
      found_license_files = LicenseFinder::GemSpecDetails.new(gem_spec).license_files
      found_license_files.map(&:file_name).should =~
            %w[BSD-2-Clause.txt GPL-2.0.txt MIT.txt RUBY.txt COPYING LICENSE]
      found_license_files.map(&:file_path).should =~
            %w[LICENSE/BSD-2-Clause.txt LICENSE/GPL-2.0.txt LICENSE/MIT.txt  LICENSE/RUBY.txt COPYING LICENSE/LICENSE]
    end
  end



  describe "#readme_files" do
    it "is empty if there aren't any readme files" do
      LicenseFinder::GemSpecDetails.new(@mock_gemspec.new).readme_files.should == []
    end

    it "includes files with names like README, Readme or COPYING" do
      gem_spec = @mock_gemspec.new('spec/fixtures/readme')
      LicenseFinder::GemSpecDetails.new(gem_spec).readme_files.map(&:file_name).should =~
          %w[Project\ ReadMe README Readme.markdown]
    end

    it "includes files deep in the hierarchy" do
      gem_spec = @mock_gemspec.new('spec/fixtures/nested_readme')
      LicenseFinder::GemSpecDetails.new(gem_spec).readme_files.map { |f| [f.file_name, f.file_path] }.should =~
          [['README', 'vendor/README']]
    end
  end

  describe 'to dependency' do
    before do
      stub(LicenseFinder).config.stub!.whitelist { ['MIT', 'Apache 2.0', 'LGPL', 'GPLv2'] }
    end

    describe 'with MIT License' do
      subject do
        LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/mit_licensed_gem')).dependency
      end

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'MIT' }
      its(:approved) { should == true }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with MIT License in README' do
      subject do
        LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/mit_licensed_gem_in_README')).dependency
      end

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'MIT' }
      its(:approved) { should == true }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with MIT License in README' do
      subject do
        LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/mit_licensed_gem_via_url')).dependency
      end

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'MIT' }
      its(:approved) { should == true }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with MIT License with hashes' do
      subject do
        LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/mit_licensed_with_hashes')).dependency
      end

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'MIT' }
      its(:approved) { should == true }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with Apache License' do
      subject do
        LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/apache_licensed_gem')).dependency
      end

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'Apache 2.0' }
      its(:approved) { should == true }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with GPLv2 License' do
      subject do
        LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/gplv2_licensed_gem')).dependency
      end

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'GPLv2' }
      its(:approved) { should == true }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with LGPL License' do
      it "should detect the license as LGPL" do
        dependency = LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/lgpl_licensed_gem')).dependency
        dependency.license.should == "LGPL"
      end
    end

    describe 'with ISC License' do
      it "should detect the license as ISC" do
        dependency = LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/isc_licensed_gem')).dependency
        dependency.license.should == "ISC"
      end
    end

    describe 'with unknown license' do
      subject { LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/other_licensed_gem')).dependency }

      its(:name) { should == 'spec_name' }
      its(:version) { should == '2.1.3' }
      its(:license) { should == 'other' }
      its(:approved) { should == false }
      its(:license_url) { should == '' }
      its(:notes) { should == '' }
    end

    describe 'with UTF8 file License' do
      it "handles non UTF8 encodings" do
        expect do
          LicenseFinder::GemSpecDetails.new(@mock_gemspec.new('spec/fixtures/utf8_gem')).dependency
        end.not_to raise_error ArgumentError, "invalid byte sequence in UTF-8"
      end
    end
  end
end
